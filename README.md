# rfabric-agent

The Rust process that runs on every [rFabric](https://rfabric.io)-managed robot. Bridges the device to the rFabric platform over IoT Core (telemetry & commands), Amazon S3 (bulk data), and interactive channel (sensor & control streams).

- Single static binary, no runtime dependencies
- linux / macOS on amd64 + arm64
- systemd-managed on Debian/Ubuntu and RHEL/Fedora via the official `.deb` / `.rpm` packages
- X.509 device identity minted on first boot from a one-time bootstrap token

## Install

```bash
# Linux / macOS - on Debian/Ubuntu (apt) and Fedora/RHEL (dnf) installs the rfabric-agent package
curl -fsSL https://get.rfabric.io/agent.sh | sh

# macOS / Linux (Homebrew) - dev laptops, custom images
brew install rfabric/tap/rfabric-agent

# Binary only (no package, no systemd service) - bare-metal installs, CI runners
curl -fsSL https://get.rfabric.io/agent.sh | RFABRIC_INSTALL_DIR=/usr/local/bin sh
```

On Linux with `apt-get` or `dnf`, `agent.sh` adds the rFabric package repository <https://linux.rfabric.io> (using `sudo` when not root) and installs the `rfabric-agent` package: the binary at `/usr/bin/rfabric-agent`, the systemd unit at `/lib/systemd/system/rfabric-agent.service`, the `rfabric` system user, and `/etc/rfabric/agent.example.toml` as a starting point. On macOS and other Linux systems, or with `RFABRIC_VERSION` / `RFABRIC_INSTALL_DIR` set, it installs the checksum-verified binary from the GitHub Release into `RFABRIC_INSTALL_DIR` (default `/usr/local/bin`). Homebrew and the binary-only install only place the binary on `PATH` - operators wanting a managed service use the package.

Upgrade with `sudo apt-get upgrade` / `sudo dnf upgrade`. `rfabric-remote` (agent with interactive media) installs from the same repository: `sudo apt-get install rfabric-remote` / `sudo dnf install rfabric-remote`.

Release candidates: `curl -fsSL https://get.rfabric.io/agent.sh | RFABRIC_CHANNEL=rc sh`. On apt/dnf systems this switches the package repository to the `rc` channel; rerunning `agent.sh` without `RFABRIC_CHANNEL` switches back to `stable`.

## Quick start

### Dev laptop / Homebrew — no sudo, no manual config copy

```bash
rfabric-agent provision prov_…
rfabric-agent run
```

`provision` writes the cert / key / CA triple, `provisioned.toml`, and a freshly generated `agent.toml` into `~/.config/rfabric/` (override with `--out-dir`). The agent picks the same directory up automatically on the next `run`. Re-running `provision` refreshes the certificate but leaves an existing `agent.toml` untouched, so operator edits survive.

There is no shared service token to copy: the agent authenticates to the rFabric API by exchanging its X.509 client certificate for a short-lived `type=robot` JWT against the mTLS robot-auth endpoint baked in at build time (override with `--robot-auth-url` on `provision` for staging / on-prem).

The bootstrap token can also be supplied via `RFABRIC_AGENT_PROVISIONING_TOKEN` to keep it out of shell history. The API endpoint is baked in at build time from the release channel (`stable` → prod, otherwise → dev); pass `--api-url https://api.<env>.rfabric.io` only when targeting a non-default environment.

### Production robot (apt / dnf) — systemd-managed

```bash
sudo rfabric-agent provision prov_… --out-dir /etc/rfabric

sudo systemctl enable --now rfabric-agent
sudo journalctl -u rfabric-agent -f
```

The systemd unit pins `RFABRIC_AGENT_CONFIG=/etc/rfabric/agent.toml`, so the service always reads the operator-owned config regardless of the per-user default.

If you forget `--out-dir` while running under `sudo`, `provision` prints a warning and falls back to `/root/.config/rfabric/` — a path the systemd unit does **not** read. Always pass `--out-dir /etc/rfabric` for the system install (or re-run without sudo for the per-user install).

`rfabric-agent --help` and `rfabric-agent <subcommand> --help` document every flag. `rfabric-agent version --output json` reports build channel, commit, and host triple — the same shape as `rfabric version --output json`.

## Documentation

- Operator guide: <https://docs.rfabric.io/agent>
- Platform docs: <https://docs.rfabric.io>

## Issues & support

Report bugs and request features in this repo's [issue tracker](https://github.com/rfabric/agent/issues).
