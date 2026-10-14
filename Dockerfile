FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        fd-find \
        git \
        gnupg \
        htop \
        jq \
        less \
        libstdc++6 \
        locales \
        nano \
        openssh-client \
        podman \
        procps \
        ripgrep \
        sudo \
        tmux \
        unzip \
        vim \
        wget \
        zsh \
    && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/github-cli.gpg \
    && curl -fsSL https://mise.jdx.dev/gpg-key.pub -o /etc/apt/keyrings/mise.asc \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/github-cli.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && echo "deb [signed-by=/etc/apt/keyrings/mise.asc] https://mise.jdx.dev/deb stable main" \
        > /etc/apt/sources.list.d/mise.list \
    && echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud.list \
    && echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com trixie main" \
        > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gh \
        google-cloud-cli \
        mise \
        terraform \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.13.1 /uv /uvx /usr/local/bin/
COPY --from=oven/bun:1.4.3-debian /usr/local/bin/bun /usr/local/bin/bun

RUN ln -s bun /usr/local/bin/bunx \
    && mkdir /usr/local/bun-node-fallback-bin \
    && ln -s /usr/local/bin/bun /usr/local/bun-node-fallback-bin/node \
    && BUN_INSTALL=/usr/local bun install -g \
        @anthropic-ai/claude-code@latest \
        @openai/codex@latest \
        opencode-ai@latest

RUN UV_TOOL_DIR=/usr/local/share/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python \
    uv tool install --python 3.13 --with-executables-from ansible-core ansible

RUN case "$(uname -m)" in \
        x86_64) code_arch=x64 ;; \
        aarch64) code_arch=arm64 ;; \
    esac \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/aws.zip \
    && unzip -q /tmp/aws.zip -d /tmp \
    && /tmp/aws/install \
    && curl -fsSL "https://update.code.visualstudio.com/latest/cli-linux-${code_arch}/stable" \
        | tar -xz -C /usr/local/bin \
    && rm -rf /tmp/aws /tmp/aws.zip

RUN RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo \
    sh -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --no-modify-path --profile minimal \
            --component clippy,rustfmt --default-toolchain stable'

COPY vscode-tunnel /usr/local/bin/vscode-tunnel

RUN useradd --create-home --uid 1000 --shell /usr/bin/zsh dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && chown -R dev:dev /usr/local/rustup \
    && printf '%s\n' \
        '[[ -o interactive && ! -e ~/.zshrc ]] && : >> ~/.zshrc 2>/dev/null' \
        > /etc/zsh/zshenv \
    && printf '%s\n' \
        'HISTFILE=~/.zsh_history' \
        'HISTSIZE=10000' \
        'SAVEHIST=10000' \
        'setopt SHARE_HISTORY' \
        'eval "$(mise activate zsh)"' \
        > /etc/zsh/zshrc

ENV HOME=/home/dev \
    RUSTUP_HOME=/usr/local/rustup \
    DISABLE_AUTOUPDATER=1 \
    PATH=/home/dev/.cargo/bin:/home/dev/.local/bin:/home/dev/.local/share/mise/shims:/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bun-node-fallback-bin

USER dev
WORKDIR /home/dev

CMD ["sleep", "infinity"]
