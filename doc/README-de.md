# repoman

**repoman** liefert **lrm** (Linux-Repo-Manager) zum Verwalten, Testen und Anwenden von apt/dnf/yum/pacman-Spiegeln.

## `lrm` Schnellstart

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Spiegel liegen unter `$XDG_CONFIG_HOME/repoman/lrm/`. Beim ersten Lauf werden Standardspiegel angelegt.

Bandbreitentests nutzen standardmäßig [getbar](https://github.com/lenik/getbar). Siehe `lrm(1)`.

Doku: `doc/README-de.md`, Handbuch `man/de/man1/lrm.1`.

## Repository-Struktur

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## Protokollierung und Farben

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

## Internationalisierung (gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=de ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## Erstellen und Installieren

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Debian-Paket

```bash
dpkg-buildpackage -us -uc
```

## Lizenz

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
