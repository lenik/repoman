# repoman

**repoman** liveras **lrm** (administranto de deponejoj por Linux): Bash-ilo por
administri, mezuri kaj apliki spegulojn de paketoj (apt, dnf/yum, pacman).

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Spegulaj difinoj estas sub `$XDG_CONFIG_HOME/repoman/lrm/`. Je la unua rulo
defaŭltaj speguloj estas kreitaj por la detektita familio (Debian, RPM aŭ Arch).

Bandwidth-testoj uzas [getbar](https://github.com/lenik/getbar) defaŭlte kun
`-c -d2 -p1 -w3 -s30m -i.1 -q`. Detaloj en `lrm(1)`.

## Arbo-strukturo

- `lrm.in` — ĉefa skripto (Meson kreas `build/lrm`)
- `lib/` — backend-moduloj (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext-katalogoj (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — manpaĝoj po lingvo (mane prizorgataj)
- `README-<lang>.md` — README po lingvo (mane prizorgataj)
- `lrm.1.in` — angla manpaĝa fonto
- `debian/` — Debian-pakaĵado
- `meson.build` — konstru-defino

## Protokolado

Kiam stderr estas TTY kaj terminfo disponeblas, linioj estas kolorigitaj (`tput`, ANSI-fallback):

| Nivelo | Flago | Koloro | Enhavo |
|--------|-------|--------|--------|
| 0 | (defaŭlte) | verda | progreso |
| 1 | `-v` | cyan | testoj po spegulo |
| 2 | `-vv` | blua | vojoj, sudo, distro |
| 3 | `-vvv` | magenta | mezuroj, komandoj |
| 4 | `-vvvv` | malhela | eliro de eksteraj iloj |
| warn | — | flava | avertoj |
| err | — | grasa ruĝa | eraroj |

`-q` subpremas ĉion krom eraroj.

## Internaciigo

### CLI-mesaĝoj (gettext)

Tekstdomajno `lrm`. Serĉ-ordo: fonta `po/`, `build/po/`, `$(localedir)`.

```bash
LANGUAGE=eo ./build/lrm -h
```

Meson kompilas `po/*.po` al `*.mo` dum konstruado (same kiel getbar).

### Manpaĝoj kaj README (mana traduko)

Anglaj fontoj: `README.md`, `lrm.1.in`. Redaktu `README-<lang>.md` kaj
`man/<lang>/lrm.1.in`. `<lang>` kongruu kun `po/LINGUAS`. Vidu `po/TRANSLATORS.md`.

## Konstruado kaj instalado

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

Opciaj rultempaj dependecoj: **getbar**, **iputils-ping**.

## Debian-pakaĵo

```bash
dpkg-buildpackage -us -uc
```

## Licenco

Copyright (C) 2026 Lenik <repoman@bodz.net>

Sub **AGPL-3.0-or-later**.
