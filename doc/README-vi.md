# repoman

**repoman** cung cấp **lrm** (trình quản lý repo Linux) để quản lý, đo tốc độ và áp mirror apt/dnf/yum/pacman.

## Bắt đầu `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Mirror nằm tại `$XDG_CONFIG_HOME/repoman/lrm/`. Lần chạy đầu sẽ tạo mirror mặc định.

Thử băng thông mặc định dùng [getbar](https://github.com/lenik/getbar). Xem `lrm(1)`.

Tài liệu: `doc/README-vi.md`, man `man/vi/man1/lrm.1`.

## Cấu trúc kho mã

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## Nhật ký và màu

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

## Quốc tế hóa (gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=vi ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## Biên dịch và cài đặt

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Gói Debian

```bash
dpkg-buildpackage -us -uc
```

## Giấy phép

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
