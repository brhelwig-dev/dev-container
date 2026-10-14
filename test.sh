#!/bin/sh
set -e
code --version
git --version
tmux -V
gh --version
mise --version
uv --version
bun --version
bunx --version
rustc --version
cargo clippy --version
cargo fmt --version
claude --version
codex --version
opencode --version
gcloud --version
aws --version
terraform version
ansible --version >/tmp/ansible.out 2>&1 || { cat /tmp/ansible.out; exit 1; }
podman --version
rg --version
jq --version
command -v vscode-tunnel
test "$(id -u)" = 1000
zsh -ic 'mise --version'
touch ~/.write-test
