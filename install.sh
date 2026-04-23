#!/usr/bin/env bash

set -euo pipefail

REPO_OWNER="${REPO_OWNER:-goropikari}"
REPO_NAME="${REPO_NAME:-git-wt}"
REPO_REF="${REPO_REF:-main}"
RAW_BASE_PREFIX="${RAW_BASE_PREFIX:-https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}}"
RAW_BASE_URL="${RAW_BASE_URL:-${RAW_BASE_PREFIX}/${REPO_REF}}"
PREFIX="${PREFIX:-$HOME/.local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
MANDIR="${MANDIR:-$PREFIX/share/man/man1}"
UNINSTALL=0

usage() {
	cat <<'EOF'
usage: install.sh [--prefix DIR] [--bindir DIR] [--mandir DIR] [--ref REF] [--branch BRANCH] [--uninstall]

Install git-wt into the current user's local directories.

options:
  --prefix DIR    install under DIR (default: ~/.local)
  --bindir DIR    install git-wt into DIR
  --mandir DIR    install git-wt.1 into DIR
  --ref REF       download files from a different git ref
  --branch BRANCH download files from a branch name (same as --ref)
  --uninstall     remove installed files instead of downloading them
  -h, --help      show this help
EOF
}

need_command() {
	local command_name="$1"
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'missing required command: %s\n' "$command_name" >&2
		exit 1
	fi
}

warn_if_path_missing() {
	case ":${PATH:-}:" in
	*:"$BINDIR":*) ;;
	*)
		printf 'warning: %s is not on PATH\n' "$BINDIR" >&2
		cat >&2 <<EOF
add this to your shell config:
  export PATH="$BINDIR:\$PATH"
EOF
		;;
	esac
}

warn_if_manpath_missing() {
	if [[ -n "${MANPATH:-}" ]]; then
		case ":$MANPATH:" in
		*:"${PREFIX}/share/man":*) ;;
		*)
			printf 'warning: %s is not on MANPATH\n' "${PREFIX}/share/man" >&2
			cat >&2 <<EOF
add this to your shell config:
  export MANPATH="${PREFIX}/share/man:\$MANPATH"
EOF
			;;
		esac
	fi
}

download_file() {
	local source_url="$1"
	local destination_path="$2"

	curl -fsSL "$source_url" -o "$destination_path"
}

set_repo_ref() {
	REPO_REF="$1"
	RAW_BASE_URL="${RAW_BASE_PREFIX}/${REPO_REF}"
}

install_files() {
	local temp_dir

	temp_dir="$(mktemp -d)"

	mkdir -p -- "$BINDIR" "$MANDIR"
	download_file "$RAW_BASE_URL/git-wt" "$temp_dir/git-wt"
	download_file "$RAW_BASE_URL/git-wt.1" "$temp_dir/git-wt.1"
	install -m 0755 "$temp_dir/git-wt" "$BINDIR/git-wt"
	install -m 0644 "$temp_dir/git-wt.1" "$MANDIR/git-wt.1"
	rm -rf -- "$temp_dir"

	printf 'installed git-wt to %s/git-wt\n' "$BINDIR"
	printf 'installed git-wt.1 to %s/git-wt.1\n' "$MANDIR"
	warn_if_path_missing
	warn_if_manpath_missing
}

uninstall_files() {
	rm -f -- "$BINDIR/git-wt" "$MANDIR/git-wt.1"
	printf 'removed %s/git-wt\n' "$BINDIR"
	printf 'removed %s/git-wt.1\n' "$MANDIR"
}

parse_args() {
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--prefix)
			PREFIX="$2"
			BINDIR="$PREFIX/bin"
			MANDIR="$PREFIX/share/man/man1"
			shift 2
			;;
		--bindir)
			BINDIR="$2"
			shift 2
			;;
		--mandir)
			MANDIR="$2"
			shift 2
			;;
		--ref | --branch)
			set_repo_ref "$2"
			shift 2
			;;
		--uninstall)
			UNINSTALL=1
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			printf 'unknown option: %s\n' "$1" >&2
			usage >&2
			exit 1
			;;
		esac
	done
}

main() {
	parse_args "$@"
	need_command curl
	need_command install

	if [[ "$UNINSTALL" -eq 1 ]]; then
		uninstall_files
		return 0
	fi

	install_files
}

main "$@"
