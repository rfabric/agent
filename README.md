# rFabric agent

The rFabric agent is a coding agent in your terminal that works on rFabric for you: it finds and runs platform operations (datasets, training runs, evaluations, simulation, robots, ...) as you, through rFabric's MCP server, and asks before every change. You bring your own model provider account.

This repository holds the agent's releases. You never download them by hand: the rFabric CLI installs and updates the agent.

## Start

Install the CLI (`brew install rfabric/tap/rfabric`, or see [rfabric/cli](https://github.com/rfabric/cli)), point it at your rFabric organization (`rfabric config init`), then in your project directory:

```bash
rfabric agent
```

The first run downloads the newest agent release and its runtime, checks both SHA-256 digests, and starts the agent. Its first session puts `/mcp reauth rfabric` in the prompt: press Enter and your browser opens the rFabric consent page for the client `rFabric agent`; sign in and approve. Sign in to your model provider with `/login` inside the agent, or keep a provider key such as `ANTHROPIC_API_KEY` in your environment.

| Command | Does |
| --- | --- |
| `rfabric agent` | Interactive session in the current directory |
| `rfabric agent --print "<prompt>"` | One prompt without the interactive UI; changes are refused |
| `rfabric agent --continue` | Continue the last session of the current CLI profile |
| `rfabric agent --resume [<id>]` | Resume a session of the current CLI profile |
| `rfabric agent update` | Install the newest agent release |
| `rfabric agent update --version <version>` | Install exactly that release, an older one included |
| `rfabric doctor` | Shows the installed agent and runtime versions |

The CLI's `--profile`, `--api-url` and `--auth-url` apply: each CLI profile has its own sessions, rFabric sign-in and model provider sign-in.

## What the agent can do

- Reach rFabric only through the MCP tools `search_operations`, `describe_operation` and `call_operation`, as the user who approved it.
- Read and change files only inside the directory you started it in.
- Move file bytes only to and from the upload and download URLs rFabric issued in the same session.
- Run no shell commands and hold no CLI credentials. Lines you type with `!` are your own commands.

Every operation that changes something asks you first, showing the operation, its parameters and body. `--print` sessions refuse changes.

## Updates

The CLI checks for a newer agent release at most once a day and prints `rfabric agent <version> is available: run rfabric agent update`. Each release pins its runtime version and the skills it carries ([rfabric/skills](https://github.com/rfabric/skills)); `rfabric agent update` shows the old and new versions. Releases are independent of CLI releases.
