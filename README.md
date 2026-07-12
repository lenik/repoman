# repoman

**repoman** ships **lrm** (Linux repo manager): a Bash tool to manage, benchmark,
and apply distribution package mirrors (apt, dnf/yum, pacman).

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Mirror definitions live under `$XDG_CONFIG_HOME/repoman/lrm/`. On first run,
built-in defaults are seeded for the detected distro family (Debian, RPM, or Arch).

Bandwidth tests use [getbar](https://github.com/lenik/getbar) with
`-c -d2 -p1 -w3 -s30m -i.1 -q` by default. See `lrm(1)` for full command
reference and scoring details.

## Repository layout

- `lrm.in` — main driver script (configured by Meson into `build/lrm`)
- `lib/` — backend modules (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — hand-translated manual pages
- `README-<lang>.md` — hand-translated readmes (see `po/LINGUAS`)
- `lrm.1.in` — English manual page source
- `debian/` — Debian packaging metadata
- `meson.build` — top-level build definition

## Logging

When stderr is a TTY and terminfo is available, `lrm` colors log lines by
verbosity level (CSI via `tput`, with ANSI fallbacks):

| Level | Flag | Color (typical) | Content |
|-------|------|-----------------|---------|
| 0 | (default) | green | normal progress |
| 1 | `-v` | cyan | per-mirror tests |
| 2 | `-vv` | blue | paths, sudo, distro |
| 3 | `-vvv` | magenta | measurements, commands |
| 4 | `-vvvv` | dim | external tool output |
| warn | — | yellow | warnings |
| err | — | bold red | errors |

Use `-q` to suppress non-error output.

## Internationalization (gettext)

User-visible strings use gettext. The text domain is `lrm`. At runtime,
`lrm` searches for message catalogs in this order:

1. **Source tree** — `po/` under the project directory (development)
2. **Build tree** — `build/po/` after `ninja` compiles `.mo` files
3. **Install prefix** — `$(localedir)` (default `/usr/share/locale`)

Set `LANGUAGE`, `LC_ALL`, or `LANG` to select a translation, for example:

```bash
LANGUAGE=zh_CN ./build/lrm -h
```

CLI catalogs live in `po/*.po` (see `po/LINGUAS`). Meson compiles them to
`*.mo` at build time via `i18n.gettext()` — same as getbar, no separate sync
target.

### Manual pages and README translations

English sources: `README.md`, `lrm.1.in`.

Other languages are **hand-maintained** — edit these files directly:

- `README-<lang>.md`
- `man/<lang>/lrm.1.in` (installed as `man/<lang>/man1/lrm.1`)

See `po/TRANSLATORS.md`. There is no documentation generator.

Legacy alias: `README-zh.md` installs from `README-zh_CN.md`.

## Build and install

### Build dependencies

```bash
sudo apt install meson ninja-build gettext
```

Optional runtime for `lrm bwtest`: **getbar**, **iputils-ping**.

### Configure and build

Use the absolute build directory `/build`:

```bash
meson setup /build
ninja -C /build
```

### Install / symlink helpers

Normal install:

```bash
meson install -C /build
```

Debug symlink workflow (under configured prefix):

```bash
ninja -C /build install-symlinks
ninja -C /build uninstall-symlinks
```

## Debian package

```bash
dpkg-buildpackage -us -uc
```

## License

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
