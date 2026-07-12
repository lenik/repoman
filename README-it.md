# repoman

**repoman** fornisce **lrm** (gestore repository Linux): uno strumento Bash per gestire,
valutare e applicare mirror di pacchetti (apt, dnf/yum, pacman).

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Le definizioni dei mirror sono in `$XDG_CONFIG_HOME/repoman/lrm/`. Al primo avvio
vengono creati mirror predefiniti per la famiglia rilevata (Debian, RPM o Arch).

I test di banda usano [getbar](https://github.com/lenik/getbar) con
`-c -d2 -p1 -w3 -s30m -i.1 -q` per default. Dettagli in `lrm(1)`.

## Struttura del repository

- `lrm.in` — script principale (Meson genera `build/lrm`)
- `lib/` — moduli backend (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — cataloghi gettext (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — manuali per lingua (manutenzione manuale)
- `README-<lang>.md` — README per lingua (manutenzione manuale)
- `lrm.1.in` — sorgente manuale inglese
- `debian/` — packaging Debian
- `meson.build` — definizione di build

## Log

Con stderr su TTY e terminfo disponibile, le righe sono colorate per livello (`tput`, fallback ANSI):

| Livello | Flag | Colore | Contenuto |
|---------|------|--------|-----------|
| 0 | (default) | verde | progresso |
| 1 | `-v` | ciano | test per mirror |
| 2 | `-vv` | blu | percorsi, sudo, distro |
| 3 | `-vvv` | magenta | misure, comandi |
| 4 | `-vvvv` | attenuato | output strumenti esterni |
| warn | — | giallo | avvisi |
| err | — | rosso grassetto | errori |

`-q` sopprime tutto tranne gli errori.

## Internazionalizzazione

### Messaggi CLI (gettext)

Dominio testuale `lrm`. Ordine di ricerca: `po/` sorgente, `build/po/`, `$(localedir)`.

```bash
LANGUAGE=it ./build/lrm -h
```

Meson compila `po/*.po` in `*.mo` in fase di build (come getbar).

### Manuali e README (traduzione manuale)

Sorgenti inglesi: `README.md`, `lrm.1.in`. Modificare `README-<lang>.md` e
`man/<lang>/lrm.1.in`. `<lang>` corrisponde a `po/LINGUAS`. Vedi `po/TRANSLATORS.md`.

## Build e installazione

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

Dipendenze runtime opzionali: **getbar**, **iputils-ping**.

## Pacchetto Debian

```bash
dpkg-buildpackage -us -uc
```

## Licenza

Copyright (C) 2026 Lenik <repoman@bodz.net>

Sotto **AGPL-3.0-or-later**.
