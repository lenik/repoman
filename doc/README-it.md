# repoman

**repoman** fornisce **lrm** (gestore repository Linux) per gestire, testare e applicare mirror apt/dnf/yum/pacman.

## Avvio rapido `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

I mirror sono in `$XDG_CONFIG_HOME/repoman/lrm/`. Al primo avvio vengono creati mirror predefiniti.

I test di banda usano [getbar](https://github.com/lenik/getbar) per default. Vedi `lrm(1)`.

Documentazione: `doc/README-it.md`, man `man/it/man1/lrm.1`.

## Struttura del repository

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## Log e colori

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

## Internazionalizzazione (gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=it ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## Compilazione e installazione

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Pacchetto Debian

```bash
dpkg-buildpackage -us -uc
```

## Licenza

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
