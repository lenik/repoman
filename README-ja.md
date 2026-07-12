# repoman

**repoman** は **lrm**（Linux リポジトリマネージャ）を提供します。apt、dnf/yum、
pacman のミラーを管理・ベンチマーク・適用する Bash ツールです。

## `lrm` の使い方

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

ミラー定義は `$XDG_CONFIG_HOME/repoman/lrm/` に保存されます。初回実行時に
検出されたディストリビューション族（Debian、RPM、Arch）向けのデフォルトが
投入されます。

帯域テストは既定で [getbar](https://github.com/lenik/getbar) を
`-c -d2 -p1 -w3 -s30m -i.1 -q` で使用します。詳細は `lrm(1)` を参照。

## リポジトリ構成

- `lrm.in` — メインドライバ（Meson が `build/lrm` を生成）
- `lib/` — バックエンド（`common.sh`、`debian.sh`、`rpm.sh`、`arch.sh` など）
- `po/` — gettext カタログ（`*.po` → `*.mo`）
- `man/<lang>/lrm.1.in` — 各言語のマニュアル（手動メンテナンス）
- `README-<lang>.md` — 各言語の README（手動メンテナンス）
- `lrm.1.in` — 英語マニュアル原文
- `debian/` — Debian パッケージング
- `meson.build` — トップレベルビルド定義

## ログと色

stderr が TTY で terminfo が使える場合、詳細度ごとに色分け（`tput` 優先、ANSI フォールバック）：

| レベル | フラグ | 色（典型） | 内容 |
|--------|--------|------------|------|
| 0 | （既定） | 緑 | 通常の進捗 |
| 1 | `-v` | シアン | ミラーごとのテスト |
| 2 | `-vv` | 青 | パス、sudo、ディストロ |
| 3 | `-vvv` | マゼンタ | 測定値とコマンド |
| 4 | `-vvvv` | 薄い | 外部ツール出力 |
| warn | — | 黄 | 警告 |
| err | — | 太字赤 | エラー |

`-q` でエラー以外を抑制できます。

## 国際化

### CLI メッセージ（gettext）

テキストドメインは `lrm`。カタログ検索順：ソース `po/`、ビルド `build/po/`、
インストール先 `$(localedir)`。

```bash
LANGUAGE=ja ./build/lrm -h
```

`po/*.po` はビルド時に Meson が `*.mo` にコンパイルします（getbar と同様）。

### マニュアルと README（手動翻訳）

英語原文：`README.md`、`lrm.1.in`。他言語は `README-<lang>.md` と
`man/<lang>/lrm.1.in` を直接編集。`<lang>` は `po/LINGUAS` と一致させる。
`po/TRANSLATORS.md` を参照。

## ビルドとインストール

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

任意の実行時依存：**getbar**、**iputils-ping**。

## Debian パッケージ

```bash
dpkg-buildpackage -us -uc
```

## ライセンス

Copyright (C) 2026 Lenik <repoman@bodz.net>

**AGPL-3.0-or-later** でライセンスされています。
