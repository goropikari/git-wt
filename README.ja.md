# `git-wt`

`git-wt` は `git worktree` を扱いやすくする Git plugin です。

`git wt add ...` は `git worktree add ...` に透過委譲したあと、リポジトリルートの `.worktreeinclude` に一致し、かつ Git で ignore されているファイルやディレクトリを、新しく作成した worktree にコピーします。

`git wt remove ...` は worktree path または branch 名を受け付けます。それ以外のサブコマンドは `git worktree` にそのまま委譲します。

## 動作要件

- Linux
- `bash`
- `git`

## インストール

Git plugin は、`PATH` 上にある `git-<name>` という実行ファイルを `git <name>` として呼び出します。\
このプロジェクトでは `git-wt` を `PATH` に置くことで `git wt` が使えるようになります。

### すぐにインストールする

```bash
curl -fsSL https://raw.githubusercontent.com/goropikari/git-wt/main/install.sh | bash
```

これにより次が配置されます。

- `~/.local/bin/git-wt`
- `~/.local/share/man/man1/git-wt.1`

次でインストール確認ができます。

```bash
git wt help
git wt --help
```

### clone してからインストールする

```bash
git clone https://github.com/goropikari/git-wt.git
cd git-wt
make install
```

これにより次が配置されます。

- `~/.local/bin/git-wt`
- `~/.local/share/man/man1/git-wt.1`

`~/.local/bin` が `PATH` に入っていない場合は、シェル設定に追加してください。

```bash
export PATH="$HOME/.local/bin:$PATH"
```

`~/.local/share/man` が `MANPATH` に入っていない場合は、こちらも追加してください。

```bash
export MANPATH="$HOME/.local/share/man:$MANPATH"
```

次でインストール確認ができます。

```bash
git wt help
git wt --help
```

### カスタム prefix にインストールする

```bash
make install PREFIX=/usr/local
```

curl インストーラを使う場合:

```bash
curl -fsSL https://raw.githubusercontent.com/goropikari/git-wt/main/install.sh | bash -s -- --prefix /usr/local
```

`DESTDIR` を使ったステージングもできます。

```bash
make install PREFIX=/usr/local DESTDIR=/tmp/package-root
```

### アンインストール

```bash
make uninstall
```

カスタム prefix を使った場合:

```bash
make uninstall PREFIX=/usr/local
```

curl インストーラを使う場合:

```bash
curl -fsSL https://raw.githubusercontent.com/goropikari/git-wt/main/install.sh | bash -s -- --uninstall
```

## 使い方

```bash
git wt add ../my-feature
git wt list
git wt remove my-feature
git wt remove ../my-feature
```

## `.worktreeinclude`

`.worktreeinclude` はリポジトリルートに置きます。\
構文は `.gitignore` 互換です。

例:

```gitignore
.env.local
.claude/
!.claude/settings.local.json
```

`git wt add ...` は、次の両方を満たすパスだけをコピーします。

- `.worktreeinclude` に一致する
- コピー元 worktree で Git に ignore されている

## 開発

```bash
make fmt
make lint
make test
```
