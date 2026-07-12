# repoman

**repoman** fournit **lrm** (gestionnaire de dépôts Linux) pour gérer, tester et appliquer des miroirs apt/dnf/yum/pacman.

## Démarrage `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Les miroirs sont dans `$XDG_CONFIG_HOME/repoman/lrm/`. Au premier lancement, des miroirs par défaut sont créés.

Les tests de bande passante utilisent [getbar](https://github.com/lenik/getbar) par défaut. Voir `lrm(1)`.

Docs : `doc/README-fr.md`, manuel `man/fr/man1/lrm.1`.

## Structure du dépôt

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## Journalisation et couleurs

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

## Internationalisation (gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=fr ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## Compilation et installation

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Paquet Debian

```bash
dpkg-buildpackage -us -uc
```

## Licence

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
