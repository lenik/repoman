# repoman

**repoman** 提供 **lrm**（Linux 軟體源管理器）：管理、測速並套用 apt/dnf/yum/pacman 鏡像。

## `lrm` 快速入門

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

鏡像設定儲存在 `$XDG_CONFIG_HOME/repoman/lrm/`。首次執行會依發行版族寫入預設鏡像。

頻寬測試預設使用 [getbar](https://github.com/lenik/getbar)。詳見 `lrm(1)`。

文件：`doc/README-zh_TW.md`，手冊 `man/zh_TW/man1/lrm.1`。

## 倉庫結構

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## 日誌與顏色

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

## 國際化（gettext）

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=zh_TW ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## 建置與安裝

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Debian 打包

```bash
dpkg-buildpackage -us -uc
```

## 授權條款

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
