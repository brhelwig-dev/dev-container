# dev-container

A Debian trixie development image for amd64 and arm64, with a VS Code tunnel server.

```
ghcr.io/brhelwig-dev/dev-container:latest
```

## What it includes

| Tool | Source |
|---|---|
| `git`, `tmux`, `zsh`, `vim`, `nano`, `htop`, `jq`, `rg`, `fd`, `build-essential`, `podman`, `ssh` | Debian packages |
| `gh` | [GitHub CLI apt repository](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| `mise` | [mise apt repository](https://mise.jdx.dev/installing-mise.html#apt) |
| `gcloud` | [Google Cloud apt repository](https://cloud.google.com/sdk/docs/install#deb) |
| `terraform` | [HashiCorp apt repository](https://developer.hashicorp.com/terraform/install) |
| `aws` | [AWS CLI v2 installer](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| `uv`, `uvx` | [`ghcr.io/astral-sh/uv`](https://github.com/astral-sh/uv) |
| `bun`, `bunx` | [`oven/bun`](https://hub.docker.com/r/oven/bun) |
| `claude`, `codex`, `opencode` | npm, through `bun install -g` |
| `ansible` | PyPI, through `uv tool install` |
| `go` | [`golang`](https://hub.docker.com/_/golang) |
| Rust stable with `clippy` and `rustfmt` | [rustup](https://rustup.rs), in `/usr/local/rustup` |
| `code` | [VS Code CLI](https://code.visualstudio.com/docs/remote/tunnels) |
| `vscode-tunnel` | Starts the tunnel server, see below |

Python comes from `uv python install` when a project needs it.

## devc

`devc` creates, opens and removes environments that use this image, with Podman, Docker
or Apple `container`. Install it:

```
curl -fsSL https://raw.githubusercontent.com/brhelwig-dev/dev-container/main/cli/install.sh | sh
```

Run `devc` in a project directory. It creates an environment named after the directory,
mounts the directory at `/workspaces/<dir>`, and opens zsh there.

| Command | Does |
|---|---|
| `devc` or `devc shell [CMD...]` | Opens zsh, or runs `CMD`, starting the environment first |
| `devc up [--no-mount]` | Creates or starts the environment; `--no-mount` skips the directory mount |
| `devc tunnel [-d]` | Starts the VS Code tunnel; `-d` runs it in the background after the first login |
| `devc stop` | Stops the environment |
| `devc rm [--purge] [-y]` | Removes the container; `--purge` also deletes its home directory |
| `devc rebuild [--no-mount\|--remount]` | Pulls the image and creates the container again; the home stays |
| `devc ls` | Lists environments |
| `devc config [KEY [VALUE]]` | Shows or sets `runtime`, `image` or `run_args` |
| `devc self-update` | Installs the latest `devc` |

`-n NAME` selects another environment. Each environment has its own home directory in
`~/.local/share/devc/<name>/home`, mounted at `/home/dev`. Mounts are fixed when the
container is created; `devc rebuild --remount` mounts the current directory instead.

`devc config runtime podman` (or `docker`, or `container`) picks the runtime. Without it,
`devc` uses the first one it finds in that order. An environment keeps the runtime it was
created with. `run_args` adds arguments to the create command. Apple `container` gives a
container 1 GiB of memory by default, so set for example
`devc config run_args '--memory 8g --cpus 4'`.

With Docker on Linux, `devc` makes uid 1000 the owner of the home directory. Your project
directory is mounted as is, so the container can write to it only when your uid is 1000.

## Run

The image runs as user `dev` (uid 1000) and idles until you open a shell or start the tunnel.
Mount a host directory at `/home/dev` to keep logins, shell history, mise installs and
`cargo install` binaries across image updates:

```
podman run -d --name dev --userns=keep-id:uid=1000,gid=1000 \
    -v ~/dev-home:/home/dev ghcr.io/brhelwig-dev/dev-container:latest
```

`--userns=keep-id:uid=1000,gid=1000` makes your host user the owner of the mount inside
the container. With Docker, give uid 1000 ownership of the directory instead.

Everything the image provides lives outside `/home/dev`, so an empty mounted home works.

## VS Code tunnel

```
podman exec -it dev vscode-tunnel
```

The first run prints a GitHub device code to enter in a browser. The login is stored in
`~/.vscode-cli`, so later runs start at once. Set `TUNNEL_NAME` to choose the tunnel name
(default: the container hostname, at most 20 characters). Then connect from VS Code with
**Remote Tunnels: Connect to Tunnel**, or open `https://vscode.dev/tunnel/<name>`.

To keep the tunnel running, start it detached: `podman exec -d dev vscode-tunnel`.

## Builds

The [workflow](.github/workflows/build.yml) builds the image on amd64 and arm64 runners,
runs [`test.sh`](test.sh) in the image, and with an empty home mounted. It pushes `latest`
from `main` and once a day, which also refreshes Debian packages, `claude`, `codex`,
`opencode`, `ansible`, `aws`, `code` and Rust. The `uv`, `bun` and `golang` images are pinned in the
`Dockerfile`, and [Dependabot](.github/dependabot.yml) opens a weekly pull request when
one has a new release.
