# `git-wt`

`git-wt` is a Git plugin that makes `git worktree` easier to use.

`git wt add ...` transparently delegates to `git worktree add ...`, then copies files and directories that match the repository-root `.worktreeinclude` file and are ignored by Git into the newly created worktree.

All other subcommands are passed through to `git worktree` unchanged.

## Requirements

- Linux
- `bash`
- `git`

## Installation

Git plugins work by placing an executable named `git-<name>` somewhere on your `PATH`.\
This project provides `git-wt`, so once that executable is available on your `PATH`, you can run `git wt`.

### Option 1: Clone and symlink

```bash
git clone https://github.com/goropikari/git-wt.git
cd git-wt
chmod +x git-wt
mkdir -p ~/.local/bin
ln -sf "$(pwd)/git-wt" ~/.local/bin/git-wt
```

If `~/.local/bin` is not already on your `PATH`, add it in your shell configuration:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then verify the installation:

```bash
git wt help
```

### Option 2: Copy the script directly

```bash
git clone https://github.com/goropikari/git-wt.git
cd git-wt
chmod +x git-wt
mkdir -p ~/.local/bin
cp git-wt ~/.local/bin/git-wt
```

## Usage

```bash
git wt add ../my-feature
git wt list
git wt remove ../my-feature
```

## `.worktreeinclude`

Place `.worktreeinclude` at the repository root.\
Its syntax follows `.gitignore`.

Example:

```gitignore
.env.local
.claude/
!.claude/settings.local.json
```

`git wt add ...` copies only paths that both:

- match `.worktreeinclude`
- are ignored by Git in the source worktree

## Development

```bash
make fmt
make lint
make test
```
