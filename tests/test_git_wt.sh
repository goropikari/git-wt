#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP_ROOT="$(mktemp -d)"

cleanup() {
	rm -rf -- "$TEST_TMP_ROOT"
}

trap cleanup EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_file_content() {
	local path="$1"
	local expected="$2"
	local actual

	[[ -f "$path" ]] || fail "missing file: $path"
	actual="$(cat "$path")"
	[[ "$actual" == "$expected" ]] || fail "unexpected file content for $path"
}

assert_exists() {
	local path="$1"
	[[ -e "$path" || -L "$path" ]] || fail "expected path to exist: $path"
}

assert_not_exists() {
	local path="$1"
	[[ ! -e "$path" && ! -L "$path" ]] || fail "expected path to be absent: $path"
}

assert_symlink_target() {
	local path="$1"
	local expected="$2"
	local actual

	[[ -L "$path" ]] || fail "expected symlink: $path"
	actual="$(readlink "$path")"
	[[ "$actual" == "$expected" ]] || fail "unexpected symlink target for $path"
}

assert_file_contains() {
	local path="$1"
	local expected="$2"

	grep -F -- "$expected" "$path" >/dev/null || fail "expected $path to contain: $expected"
}

assert_dir_not_exists() {
	local path="$1"
	[[ ! -d "$path" ]] || fail "expected directory to be absent: $path"
}

assert_command_output_eq() {
	local left="$1"
	local right="$2"
	[[ "$left" == "$right" ]] || fail "command outputs differ"
}

make_repo() {
	local name="$1"
	local repo="$TEST_TMP_ROOT/$name"

	mkdir -p -- "$repo"
	git -C "$repo" init -b main >/dev/null
	git -C "$repo" config user.name tester
	git -C "$repo" config user.email tester@example.com

	printf 'tracked\n' >"$repo/README.md"
	git -C "$repo" add README.md
	git -C "$repo" commit -m init >/dev/null

	printf '%s\n' "$repo"
}

run_git_wt() {
	PATH="$ROOT_DIR:$PATH" git -C "$1" wt "${@:2}"
}

test_passthrough_list() {
	local repo
	local expected
	local actual

	repo="$(make_repo passthrough)"
	expected="$(git -C "$repo" worktree list --porcelain)"
	actual="$(run_git_wt "$repo" list --porcelain)"

	assert_command_output_eq "$actual" "$expected"
}

test_help_output() {
	local repo
	local output

	repo="$(make_repo help)"
	output="$(run_git_wt "$repo" help)"

	[[ "$output" == *"usage: git wt <subcommand> [args...]"* ]] || fail "missing usage in help output"
	[[ "$output" == *".worktreeinclude"* ]] || fail "missing .worktreeinclude section in help output"
}

test_add_copies_ignored_file() {
	local repo
	local worktree

	repo="$(make_repo copy-file)"
	worktree="$TEST_TMP_ROOT/copy-file-wt"

	printf '.env.local\n' >"$repo/.gitignore"
	printf '.env.local\n' >"$repo/.worktreeinclude"
	printf 'SECRET=source\n' >"$repo/.env.local"
	git -C "$repo" add .gitignore .worktreeinclude
	git -C "$repo" commit -m "configure worktreeinclude" >/dev/null

	run_git_wt "$repo" add "$worktree"

	assert_file_content "$worktree/.env.local" 'SECRET=source'
}

test_add_only_copies_ignored_matches() {
	local repo
	local worktree

	repo="$(make_repo ignored-only)"
	worktree="$TEST_TMP_ROOT/ignored-only-wt"

	printf 'ignored.local\n' >"$repo/.gitignore"
	printf '*\n' >"$repo/.worktreeinclude"
	printf 'ignored\n' >"$repo/ignored.local"
	printf 'unignored\n' >"$repo/unignored.local"
	git -C "$repo" add .gitignore .worktreeinclude
	git -C "$repo" commit -m "configure ignored only" >/dev/null

	run_git_wt "$repo" add "$worktree"

	assert_file_content "$worktree/ignored.local" 'ignored'
	assert_not_exists "$worktree/unignored.local"
}

test_add_copies_symlink_and_empty_dir() {
	local repo
	local worktree

	repo="$(make_repo symlink-dir)"
	worktree="$TEST_TMP_ROOT/symlink-dir-wt"

	printf 'cache/\nlink.local\n' >"$repo/.gitignore"
	printf 'cache/\nlink.local\n' >"$repo/.worktreeinclude"
	mkdir -p -- "$repo/cache"
	ln -s -- README.md "$repo/link.local"
	git -C "$repo" add .gitignore .worktreeinclude
	git -C "$repo" commit -m "configure symlink and dir" >/dev/null

	run_git_wt "$repo" add "$worktree"

	assert_exists "$worktree/cache"
	[[ -d "$worktree/cache" ]] || fail "expected directory: $worktree/cache"
	assert_symlink_target "$worktree/link.local" 'README.md'
}

test_missing_worktreeinclude_is_noop() {
	local repo
	local worktree

	repo="$(make_repo no-include)"
	worktree="$TEST_TMP_ROOT/no-include-wt"

	printf '.env.local\n' >"$repo/.gitignore"
	printf 'SECRET=source\n' >"$repo/.env.local"
	git -C "$repo" add .gitignore
	git -C "$repo" commit -m "configure no include" >/dev/null

	run_git_wt "$repo" add "$worktree"

	assert_not_exists "$worktree/.env.local"
}

test_copy_failure_returns_nonzero_and_preserves_worktree() {
	local repo
	local worktree
	local wrapper_dir
	local status=0

	repo="$(make_repo copy-failure)"
	worktree="$TEST_TMP_ROOT/copy-failure-wt"
	wrapper_dir="$TEST_TMP_ROOT/wrappers"
	mkdir -p -- "$wrapper_dir"

	printf '.env.local\n' >"$repo/.gitignore"
	printf '.env.local\n' >"$repo/.worktreeinclude"
	printf 'SECRET=source\n' >"$repo/.env.local"
	git -C "$repo" add .gitignore .worktreeinclude
	git -C "$repo" commit -m "configure copy failure" >/dev/null

	cat >"$wrapper_dir/rsync" <<'EOF'
#!/usr/bin/env bash
printf 'simulated rsync failure\n' >&2
exit 1
EOF
	chmod +x "$wrapper_dir/rsync"

	cat >"$wrapper_dir/cp" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == *".env.local" ]]; then
    printf 'simulated cp failure\n' >&2
    exit 1
  fi
done
exec /bin/cp "$@"
EOF
	chmod +x "$wrapper_dir/cp"

	set +e
	PATH="$wrapper_dir:$ROOT_DIR:$PATH" git -C "$repo" wt add "$worktree"
	status=$?
	set -e

	[[ "$status" -ne 0 ]] || fail "expected nonzero exit code on copy failure"
	assert_exists "$worktree"
	assert_not_exists "$worktree/.env.local"
}

test_install_script_installs_and_uninstalls() {
	local install_root
	local raw_base

	install_root="$TEST_TMP_ROOT/install-root"
	raw_base="file://$ROOT_DIR"

	RAW_BASE_URL="$raw_base" PREFIX="$install_root" "$ROOT_DIR/install.sh"

	assert_exists "$install_root/bin/git-wt"
	assert_exists "$install_root/share/man/man1/git-wt.1"
	assert_file_contains "$install_root/share/man/man1/git-wt.1" '.TH GIT-WT 1'

	RAW_BASE_URL="$raw_base" PREFIX="$install_root" "$ROOT_DIR/install.sh" --uninstall

	assert_not_exists "$install_root/bin/git-wt"
	assert_not_exists "$install_root/share/man/man1/git-wt.1"
}

test_install_script_accepts_branch_option() {
	local install_root
	local raw_root

	install_root="$TEST_TMP_ROOT/install-branch-root"
	raw_root="$TEST_TMP_ROOT/raw"
	mkdir -p -- "$raw_root/feature/test"
	cp -- "$ROOT_DIR/git-wt" "$raw_root/feature/test/git-wt"
	cp -- "$ROOT_DIR/git-wt.1" "$raw_root/feature/test/git-wt.1"

	RAW_BASE_PREFIX="file://$raw_root" PREFIX="$install_root" \
		"$ROOT_DIR/install.sh" --branch feature/test

	assert_exists "$install_root/bin/git-wt"
	assert_exists "$install_root/share/man/man1/git-wt.1"
}

test_update_replaces_installed_script() {
	local repo
	local install_root
	local installed_script
	local raw_base

	repo="$(make_repo update-script)"
	install_root="$TEST_TMP_ROOT/update-root"
	installed_script="$install_root/bin/git-wt"
	raw_base="file://$ROOT_DIR"

	mkdir -p -- "$install_root/bin"
	cp -- "$ROOT_DIR/git-wt" "$installed_script"
	perl -0pi -e 's/show this help/show stale help/' "$installed_script"

	RAW_BASE_URL="$raw_base" PATH="$install_root/bin:$PATH" git -C "$repo" wt update >/dev/null

	assert_not_exists "$installed_script.bak"
	assert_file_contains "$installed_script" 'show this help'
	! grep -F -- 'show stale help' "$installed_script" >/dev/null || fail "expected installed script to be replaced"
}

test_remove_resolves_branch_to_worktree() {
	local repo
	local worktree

	repo="$(make_repo remove-branch)"
	worktree="$TEST_TMP_ROOT/remove-branch-wt"

	run_git_wt "$repo" add "$worktree" -b feature

	assert_exists "$worktree"
	run_git_wt "$repo" remove feature
	assert_dir_not_exists "$worktree"
}

test_remove_resolves_branch_with_force_option() {
	local repo
	local worktree

	repo="$(make_repo remove-branch-force)"
	worktree="$TEST_TMP_ROOT/remove-branch-force-wt"

	run_git_wt "$repo" add "$worktree" -b feature-force
	printf 'dirty\n' >"$worktree/untracked.txt"

	assert_exists "$worktree"
	run_git_wt "$repo" remove -f feature-force
	assert_dir_not_exists "$worktree"
}

test_remove_prefers_existing_path_over_branch_name() {
	local repo
	local worktree
	local branch_name

	repo="$(make_repo remove-path-preferred)"
	worktree="$TEST_TMP_ROOT/remove-path-preferred-wt"
	branch_name="$(basename "$worktree")"

	run_git_wt "$repo" add "$worktree" -b "$branch_name"

	assert_exists "$worktree"
	run_git_wt "$repo" remove "$worktree"
	assert_dir_not_exists "$worktree"
}

test_remove_falls_back_when_existing_path_is_not_worktree() {
	local repo
	local worktree
	local branch_name

	repo="$(make_repo remove-path-fallback)"
	worktree="$TEST_TMP_ROOT/remove-path-fallback-wt"
	branch_name='foo'

	run_git_wt "$repo" add "$worktree" -b "$branch_name"
	mkdir -p -- "$repo/$branch_name"

	assert_exists "$worktree"
	assert_exists "$repo/$branch_name"
	run_git_wt "$repo" remove "$branch_name"
	assert_dir_not_exists "$worktree"
	assert_exists "$repo/$branch_name"
}

test_remove_unknown_branch_returns_nonzero() {
	local repo
	local stderr_file
	local status=0

	repo="$(make_repo remove-missing-branch)"
	stderr_file="$TEST_TMP_ROOT/remove-missing-branch.err"

	set +e
	run_git_wt "$repo" remove missing-branch 2>"$stderr_file"
	status=$?
	set -e

	[[ "$status" -ne 0 ]] || fail "expected nonzero exit code for unknown branch"
	assert_file_contains "$stderr_file" 'no worktree found for branch: missing-branch'
}

run_test() {
	local name="$1"

	printf 'RUN %s\n' "$name"
	"$name"
	printf 'PASS %s\n' "$name"
}

main() {
	run_test test_help_output
	run_test test_passthrough_list
	run_test test_add_copies_ignored_file
	run_test test_add_only_copies_ignored_matches
	run_test test_add_copies_symlink_and_empty_dir
	run_test test_missing_worktreeinclude_is_noop
	run_test test_copy_failure_returns_nonzero_and_preserves_worktree
	run_test test_remove_resolves_branch_to_worktree
	run_test test_remove_resolves_branch_with_force_option
	run_test test_remove_prefers_existing_path_over_branch_name
	run_test test_remove_falls_back_when_existing_path_is_not_worktree
	run_test test_remove_unknown_branch_returns_nonzero
	run_test test_install_script_installs_and_uninstalls
	run_test test_install_script_accepts_branch_option
	run_test test_update_replaces_installed_script
}

main "$@"
