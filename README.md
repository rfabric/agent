# rfabric-agent

The Rust process that runs on every [rFabric](https://rfabric.io)-managed robot. Bridges the device to the rFabric platform over AWS IoT Core (telemetry & commands), Amazon S3 (bulk data), and LiveKit (interactive media — planned).

- Single static binary, no runtime dependencies
- linux / macOS on amd64 + arm64
- systemd-managed on Debian/Ubuntu and RHEL/Fedora via the official `.deb` / `.rpm` packages
- X.509 device identity minted on first boot from a one-time bootstrap token

## Install

```bash
# Debian / Ubuntu (apt) — recommended for production robots
curl -1sLf https://dl.cloudsmith.io/public/rfabric/release/setup.deb.sh | sudo -E bash
sudo apt install rfabric-agent

# RHEL / Fedora (yum / dnf)
curl -1sLf https://dl.cloudsmith.io/public/rfabric/release/setup.rpm.sh | sudo -E bash
sudo dnf install rfabric-agent

# macOS / Linux (Homebrew) — dev laptops, custom images
brew install rfabric/tap/rfabric-agent

# Any POSIX (curl) — bare-metal installs, CI runners
curl -fsSL https://raw.githubusercontent.com/rfabric/agent/main/install.sh | sh
```

The `.deb` / `.rpm` packages install the binary to `/usr/bin/rfabric-agent`, drop the systemd unit at `/lib/systemd/system/rfabric-agent.service`, create the `rfabric` system user, and ship `/etc/rfabric/agent.example.toml` as a starting point. Homebrew and `install.sh` only place the binary on `PATH` — operators wanting a managed service should use the OS package.

Pre-release builds are available on the `rfabric/rc` channel on Cloudsmith.

## Quick start

### Dev laptop / Homebrew — no sudo, no manual config copy

```bash
rfabric-agent provision prov_…
rfabric-agent run
```

`provision` writes the cert / key / CA triple, `provisioned.toml`, and a freshly generated `agent.toml` into `~/.config/rfabric/` (override with `--out-dir`). The agent picks the same directory up automatically on the next `run`. Re-running `provision` refreshes the certificate but leaves an existing `agent.toml` untouched, so operator edits survive.

There is no shared service token to copy: the agent authenticates to the rFabric API by exchanging its X.509 client certificate for a short-lived `type=robot` JWT against the mTLS robot-auth endpoint baked in at build time (override with `--robot-auth-url` on `provision` for staging / on-prem).

The bootstrap token can also be supplied via `RFABRIC_AGENT_PROVISIONING_TOKEN` to keep it out of shell history. The API endpoint is baked in at build time from the release channel (`stable` → prod, otherwise → dev); pass `--api-url https://api.<env>.rfabric.io` only when targeting a non-default environment.

### Production robot (apt / yum) — systemd-managed

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
