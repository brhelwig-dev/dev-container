#!/bin/sh
set -eu

main() {
	dir=${DEVC_INSTALL_DIR:-$HOME/.local/bin}
	mkdir -p "$dir"
	tmp=$(mktemp "$dir/.devc.XXXXXX")
	trap 'rm -f "$tmp"' EXIT
	curl -fsSL https://raw.githubusercontent.com/brhelwig-dev/dev-container/main/cli/devc -o "$tmp"
	chmod 755 "$tmp"
	mv "$tmp" "$dir/devc"
	echo "Installed $dir/devc"
	case ":$PATH:" in
	*":$dir:"*) ;;
	*) echo "Add $dir to your PATH" ;;
	esac
}

main
