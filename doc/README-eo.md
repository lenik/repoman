# repoman

**repoman** provizas **lrm** (Linux-depozaj administranto) por administri, mezuri kaj apliki spegulojn apt/dnf/yum/pacman.

## Rapida starto `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Speguloj estas en `$XDG_CONFIG_HOME/repoman/lrm/`. Je unua rulo kreiĝas defaŭltaj speguloj.

Bandwidth-testoj defaŭlte uzas [getbar](https://github.com/lenik/getbar). Vidu `lrm(1)`.

Dokumentado: `doc/README-eo.md`, manlibro `man/eo/man1/lrm.1`.

## Strukturo de la deponejo

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## Protokolo kaj koloroj

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

## Internaciigo (gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=eo ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## Kompilado kaj instalado

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Debian-pakaĵo

```bash
dpkg-buildpackage -us -uc
```

## Licenco

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
