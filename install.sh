#!/bin/sh
# rFabric robot agent installer.
#
# Mirrors `https://get.rfabric.io` (the CLI installer) for the agent binary.
# For production robots prefer the apt/yum repos (Cloudsmith) — they own the
# systemd unit, the `rfabric` user, and clean upgrades. This script is for
# bare-metal installs, custom images, and CI runners that just need the
# binary on PATH.
#
# Usage:
#   curl -fsSL https://get.rfabric.io/agent | sh
#
# Environment variables:
#   RFABRIC_AGENT_VERSION      Specific version (e.g. v1.4.0). Default: latest stable.
#   RFABRIC_AGENT_CHANNEL      "stable" (default) or "rc" — selects a channel when no version is pinned.
#   RFABRIC_AGENT_INSTALL_DIR  Directory to install into. Default: /usr/local/bin.

set -eu

RFABRIC_AGENT_REPO="rfabric/agent"
RFABRIC_AGENT_CHANNEL="${RFABRIC_AGENT_CHANNEL:-stable}"
RFABRIC_AGENT_INSTALL_DIR="${RFABRIC_AGENT_INSTALL_DIR:-/usr/local/bin}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

require() {
    command -v "$1" >/dev/null 2>&1 || err "missing required tool: $1"
}

require curl
require tar
require uname
require grep
require sed

detect_os() {
    case "$(uname -s)" in
        Linux)  echo linux ;;
        Darwin) echo darwin ;;
        *)      err "unsupported OS: $(uname -s) — see https://github.com/${RFABRIC_AGENT_REPO}/releases for manual install" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)   echo amd64 ;;
        arm64|aarch64)  echo arm64 ;;
        *)              err "unsupported architecture: $(uname -m)" ;;
    esac
}

resolve_version() {
    if [ -n "${RFABRIC_AGENT_VERSION:-}" ]; then
        echo "${RFABRIC_AGENT_VERSION}"
        return
    fi

    api="https://api.github.com/repos/${RFABRIC_AGENT_REPO}/releases"
    case "${RFABRIC_AGENT_CHANNEL}" in
        stable) api="${api}/latest" ;;
        rc)     api="${api}?per_page=20" ;;
        *)      err "unknown channel: ${RFABRIC_AGENT_CHANNEL} (expected stable|rc)" ;;
    esac

    response=$(curl -fsSL "${api}") || err "could not query GitHub releases API"

    if [ "${RFABRIC_AGENT_CHANNEL}" = "rc" ]; then
        tag=$(printf '%s' "${response}" | grep -E '"tag_name":' | grep -E -- '-rc\.' | head -n1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    else
        tag=$(printf '%s' "${response}" | grep -E '"tag_name":' | head -n1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    fi

    [ -n "${tag}" ] || err "no release found for channel ${RFABRIC_AGENT_CHANNEL}"
    echo "${tag}"
}

install_to_dir() {
    src_binary="$1"
    target="${RFABRIC_AGENT_INSTALL_DIR}/rfabric-agent"

    if [ -w "${RFABRIC_AGENT_INSTALL_DIR}" ]; then
        install_cmd=""
    elif command -v sudo >/dev/null 2>&1; then
        install_cmd="sudo"
    else
        err "${RFABRIC_AGENT_INSTALL_DIR} is not writable and sudo is unavailable"
    fi

    ${install_cmd} mkdir -p "${RFABRIC_AGENT_INSTALL_DIR}"
    ${install_cmd} install -m 0755 "${src_binary}" "${target}"
    log "installed to ${target}"
}

main() {
    os=$(detect_os)
    arch=$(detect_arch)
    tag=$(resolve_version)
    version="${tag#v}"

    log "rFabric robot agent installer"
    log "  channel:  ${RFABRIC_AGENT_CHANNEL}"
    log "  version:  ${tag}"
    log "  platform: ${os}/${arch}"
    log "  target:   ${RFABRIC_AGENT_INSTALL_DIR}/rfabric-agent"

    archive="rfabric-agent_${version}_${os}_${arch}.tar.gz"
    base_url="https://github.com/${RFABRIC_AGENT_REPO}/releases/download/${tag}"

    tmp=$(mktemp -d)
    trap 'rm -rf "${tmp}"' EXIT

    log "downloading ${archive}"
    curl -fsSL -o "${tmp}/${archive}" "${base_url}/${archive}" \
        || err "failed to download ${base_url}/${archive}"

    log "verifying checksum"
    curl -fsSL -o "${tmp}/checksums.txt" "${base_url}/checksums.txt" \
        || err "failed to download checksums.txt"

    expected=$(grep -E " ${archive}\$" "${tmp}/checksums.txt" | awk '{print $1}')
    [ -n "${expected}" ] || err "no checksum entry for ${archive}"

    if command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "${tmp}/${archive}" | awk '{print $1}')
    else
        actual=$(shasum -a 256 "${tmp}/${archive}" | awk '{print $1}')
    fi
    [ "${actual}" = "${expected}" ] || err "checksum mismatch (expected ${expected}, got ${actual})"

    log "extracting"
    tar -xzf "${tmp}/${archive}" -C "${tmp}"

    install_to_dir "${tmp}/rfabric-agent"

    log "verifying installation"
    "${RFABRIC_AGENT_INSTALL_DIR}/rfabric-agent" version || err "installed binary failed to run"

    log "done — next: 'rfabric-agent provision <token>' (see https://github.com/${RFABRIC_AGENT_REPO})"
}

main "$@"
