# repoman

**repoman** มี **lrm** (ตัวจัดการ repo ของ Linux) สำหรับจัดการ ทดสอบ และใช้มิเรอร์ apt/dnf/yum/pacman

## เริ่มต้น `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

มิเรอร์อยู่ที่ `$XDG_CONFIG_HOME/repoman/lrm/` ครั้งแรกจะสร้างมิเรอร์เริ่มต้น

ทดสอบแบนด์วิดท์ใช้ [getbar](https://github.com/lenik/getbar) ตามค่าเริ่มต้น ดู `lrm(1)`

เอกสาร: `doc/README-th.md` คู่มือ `man/th/man1/lrm.1`

## โครงสร้างที่เก็บ

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## บันทึกและสี

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

## การแปลภาษา (gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=th ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## สร้างและติดตั้ง

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## แพ็กเกจ Debian

```bash
dpkg-buildpackage -us -uc
```

## สัญญาอนุญาต

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
