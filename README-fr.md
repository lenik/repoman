# repoman

**repoman** fournit **lrm** (gestionnaire de dépôts Linux) : un outil Bash pour
gérer, évaluer et appliquer les miroirs de paquets (apt, dnf/yum, pacman).

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Les miroirs sont définis sous `$XDG_CONFIG_HOME/repoman/lrm/`. Au premier lancement,
des valeurs par défaut sont créées pour la famille détectée (Debian, RPM ou Arch).

Les tests de bande passante utilisent [getbar](https://github.com/lenik/getbar) avec
`-c -d2 -p1 -w3 -s30m -i.1 -q` par défaut. Voir `lrm(1)` pour les détails.

## Arborescence

- `lrm.in` — script principal (Meson produit `build/lrm`)
- `lib/` — modules backend (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — catalogues gettext (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — pages de manuel par langue (maintenance manuelle)
- `README-<lang>.md` — README par langue (maintenance manuelle)
- `lrm.1.in` — source du manuel anglais
- `debian/` — métadonnées Debian
- `meson.build` — définition de build

## Journalisation

Sur un TTY avec terminfo, les lignes sont colorées par niveau (`tput`, repli ANSI) :

| Niveau | Option | Couleur | Contenu |
|--------|--------|---------|---------|
| 0 | (défaut) | vert | progression |
| 1 | `-v` | cyan | tests par miroir |
| 2 | `-vv` | bleu | chemins, sudo, distro |
| 3 | `-vvv` | magenta | mesures, commandes |
| 4 | `-vvvv` | atténué | sortie outils externes |
| warn | — | jaune | avertissements |
| err | — | rouge gras | erreurs |

`-q` supprime tout sauf les erreurs.

## Internationalisation

### Messages CLI (gettext)

Domaine de texte `lrm`. Ordre de recherche : `po/` source, `build/po/`, `$(localedir)`.

```bash
LANGUAGE=fr ./build/lrm -h
```

Meson compile `po/*.po` en `*.mo` à la compilation (comme getbar).

### Manuels et README (traduction manuelle)

Sources anglaises : `README.md`, `lrm.1.in`. Éditez `README-<lang>.md` et
`man/<lang>/lrm.1.in`. `<lang>` doit correspondre à `po/LINGUAS`. Voir `po/TRANSLATORS.md`.

## Compilation et installation

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

Dépendances d'exécution optionnelles : **getbar**, **iputils-ping**.

## Paquet Debian

```bash
dpkg-buildpackage -us -uc
```

## Licence

Copyright (C) 2026 Lenik <repoman@bodz.net>

Sous **AGPL-3.0-or-later**.
