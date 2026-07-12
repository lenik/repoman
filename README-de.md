# repoman

**repoman** liefert **lrm** (Linux-Repository-Manager): ein Bash-Werkzeug zum Verwalten,
Benchmarken und Anwenden von Paketspiegeln (apt, dnf/yum, pacman).

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Spiegeldefinitionen liegen unter `$XDG_CONFIG_HOME/repoman/lrm/`. Beim ersten Lauf
werden Standardspiegel für die erkannte Familie (Debian, RPM oder Arch) angelegt.

Bandbreitentests nutzen standardmäßig [getbar](https://github.com/lenik/getbar) mit
`-c -d2 -p1 -w3 -s30m -i.1 -q`. Details in `lrm(1)`.

## Repository-Aufbau

- `lrm.in` — Hauptskript (Meson erzeugt `build/lrm`)
- `lib/` — Backend-Module (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext-Kataloge (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — Handbuchseiten pro Sprache (manuell gepflegt)
- `README-<lang>.md` — README pro Sprache (manuell gepflegt)
- `lrm.1.in` — englische Handbuchquelle
- `debian/` — Debian-Packaging
- `meson.build` — Build-Definition

## Protokollierung

Bei TTY und terminfo werden Zeilen nach Stufe eingefärbt (`tput`, ANSI-Fallback):

| Stufe | Schalter | Farbe | Inhalt |
|-------|----------|-------|--------|
| 0 | (Standard) | grün | Fortschritt |
| 1 | `-v` | cyan | Tests pro Spiegel |
| 2 | `-vv` | blau | Pfade, sudo, Distro |
| 3 | `-vvv` | magenta | Messwerte, Befehle |
| 4 | `-vvvv` | gedimmt | externe Tool-Ausgabe |
| warn | — | gelb | Warnungen |
| err | — | fett rot | Fehler |

`-q` unterdrückt alles außer Fehlern.

## Internationalisierung

### CLI-Meldungen (gettext)

Textdomäne `lrm`. Suchreihenfolge: Quell-`po/`, `build/po/`, `$(localedir)`.

```bash
LANGUAGE=de ./build/lrm -h
```

Meson kompiliert `po/*.po` beim Build zu `*.mo` (wie getbar).

### Handbücher und README (manuelle Übersetzung)

Englische Quellen: `README.md`, `lrm.1.in`. Bearbeiten Sie `README-<lang>.md` und
`man/<lang>/lrm.1.in`. `<lang>` entspricht `po/LINGUAS`. Siehe `po/TRANSLATORS.md`.

## Build und Installation

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

Optionale Laufzeitabhängigkeiten: **getbar**, **iputils-ping**.

## Debian-Paket

```bash
dpkg-buildpackage -us -uc
```

## Lizenz

Copyright (C) 2026 Lenik <repoman@bodz.net>

Unter **AGPL-3.0-or-later**.
