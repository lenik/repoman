# repoman

**repoman** 提供 **lrm**（Linux 软件源管理器）：管理、测速并应用 apt/dnf/yum/pacman 镜像。

## `lrm` 快速上手

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

镜像配置保存在 `$XDG_CONFIG_HOME/repoman/lrm/`。首次运行会按发行版族写入默认镜像。

带宽测试默认使用 [getbar](https://github.com/lenik/getbar)。详见 `lrm(1)`。

文档：`doc/README-zh_CN.md`，手册 `man/zh_CN/man1/lrm.1`。

## 仓库结构

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## 日志与颜色

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

## 国际化（gettext）

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=zh_CN ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## 构建与安装

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

## 许可证

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
