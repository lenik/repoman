# repoman

**repoman** は **lrm**（Linux リポジトリマネージャ）を提供します。apt/dnf/yum/pacman のミラーを管理・測定・適用します。

## `lrm` クイックスタート

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

ミラーは `$XDG_CONFIG_HOME/repoman/lrm/` に保存されます。初回実行時に既定ミラーを作成します。

帯域テストは既定で [getbar](https://github.com/lenik/getbar) を使用。詳細は `lrm(1)`。

ドキュメント: `doc/README-ja.md`、マニュアル `man/ja/man1/lrm.1`。

## リポジトリ構成

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## ログと色

| Level | Flag | Color | Content |
|-------|------|-------|---------|
| 0 | (default) | green | normal progress |
| 1 | `-v` | cyan | per-mirror tests |
| 2 | `-vv` | blue | paths, sudo, distro |
| 3 | `-vvv` | magenta | measurements |
| 4 | `-vvvv` | dim | tool output |
| warn | — | yellow | warnings |
| err | — | bold red | errors |

Use `-q` to suppress non-error output.

## 国際化（gettext）

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=ja ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## ビルドとインストール

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Debian パッケージ

```bash
dpkg-buildpackage -us -uc
```

## ライセンス

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
