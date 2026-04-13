# `git-wt`

`git-wt` は `git worktree` を扱いやすくする Git plugin です。

`git wt add ...` は `git worktree add ...` に透過委譲したあと、リポジトリルートの `.worktreeinclude` に一致し、かつ Git で ignore されているファイルやディレクトリを、新しく作成した worktree にコピーします。

それ以外のサブコマンドは `git worktree` にそのまま委譲します。

## 動作要件

- Linux
- `bash`
- `git`

## インストール

Git plugin は、`PATH` 上にある `git-<name>` という実行ファイルを `git <name>` として呼び出します。\
このプロジェクトでは `git-wt` を `PATH` に置くことで `git wt` が使えるようになります。

### 方法 1: clone して symlink を張る

```bash
git clone https://github.com/goropikari/git-wt.git
cd git-wt
chmod +x git-wt
mkdir -p ~/.local/bin
ln -sf "$(pwd)/git-wt" ~/.local/bin/git-wt
```

`~/.local/bin` が `PATH` に入っていない場合は、シェル設定に追加してください。

```bash
export PATH="$HOME/.local/bin:$PATH"
```

次でインストール確認ができます。

```bash
git wt help
```

### 方法 2: スクリプトを直接コピーする

```bash
git clone https://github.com/goropikari/git-wt.git
cd git-wt
chmod +x git-wt
mkdir -p ~/.local/bin
cp git-wt ~/.local/bin/git-wt
```

## 使い方

```bash
git wt add ../my-feature
git wt list
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
