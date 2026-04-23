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

```bash
# 1. On the robot, mint a device certificate from a one-time bootstrap token
sudo rfabric-agent provision \
    --api-url https://api.rfabric.io \
    --token   prov_…              \
    --out-dir /etc/rfabric

# 2. Drop your operator-owned config alongside it
sudo cp /etc/rfabric/agent.example.toml /etc/rfabric/agent.toml
sudo $EDITOR /etc/rfabric/agent.env       # set RFABRIC_AGENT_SERVICE_TOKEN

# 3. Smoke test, then start the service
sudo -u rfabric rfabric-agent --config /etc/rfabric/agent.toml doctor
sudo systemctl enable --now rfabric-agent
sudo journalctl -u rfabric-agent -f
```

`rfabric-agent --help` and `rfabric-agent <subcommand> --help` document every flag. `rfabric-agent version --output json` reports build channel, commit, and host triple — the same shape as `rfabric version --output json`.

## Documentation

- Operator guide: <https://docs.rfabric.io/agent>
- Platform docs: <https://docs.rfabric.io>

## Issues & support

Report bugs and request features in this repo's [issue tracker](https://github.com/rfabric/agent/issues).
