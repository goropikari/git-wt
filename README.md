# `git-wt`

`git-wt` is a Git plugin that makes `git worktree` easier to use.

`git wt add ...` transparently delegates to `git worktree add ...`, then copies files and directories that match the repository-root `.worktreeinclude` file and are ignored by Git into the newly created worktree.

`git wt remove ...` accepts either a worktree path or a branch name. `git wt update` replaces the installed `git-wt` script with the latest downloaded version. All other subcommands are passed through to `git worktree` unchanged.

## Requirements

- Linux
- `bash`
- `git`

## Installation

Git plugins work by placing an executable named `git-<name>` somewhere on your `PATH`.\
This project provides `git-wt`, so once that executable is available on your `PATH`, you can run `git wt`.

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/goropikari/git-wt/main/install.sh | bash
```

This installs:

- `git-wt` to `~/.local/bin/git-wt`
- `git-wt.1` to `~/.local/share/man/man1/git-wt.1`

Then verify the installation:

```bash
git wt help
git wt --help
```

### Install from a cloned repository

```bash
git clone https://github.com/goropikari/git-wt.git
cd git-wt
make install
```

This installs:

- `git-wt` to `~/.local/bin/git-wt`
- `git-wt.1` to `~/.local/share/man/man1/git-wt.1`

If `~/.local/bin` is not already on your `PATH`, add it in your shell configuration:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

If `~/.local/share/man` is not already on your `MANPATH`, add it as well:

```bash
export MANPATH="$HOME/.local/share/man:$MANPATH"
```

Then verify the installation:

```bash
git wt help
git wt --help
```

### Install to a custom prefix

```bash
make install PREFIX=/usr/local
```

For the curl installer:

```bash
curl -fsSL https://raw.githubusercontent.com/goropikari/git-wt/main/install.sh | bash -s -- --prefix /usr/local
```

You can also stage an installation with `DESTDIR`:

```bash
make install PREFIX=/usr/local DESTDIR=/tmp/package-root
```

### Uninstall

```bash
make uninstall
```

For a custom prefix:

```bash
make uninstall PREFIX=/usr/local
```

For the curl installer:

```bash
curl -fsSL https://raw.githubusercontent.com/goropikari/git-wt/main/install.sh | bash -s -- --uninstall
```

## Usage

```bash
git wt add ../my-feature
git wt list
git wt remove my-feature
git wt remove ../my-feature
git wt update
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
