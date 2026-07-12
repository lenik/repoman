# repoman

**repoman**은 **lrm**(Linux 저장소 관리자)을 제공합니다. apt/dnf/yum/pacman 미러를 관리·벤치마크·적용합니다.

## `lrm` 빠른 시작

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

미러는 `$XDG_CONFIG_HOME/repoman/lrm/`에 저장됩니다. 첫 실행 시 기본 미러를 씁니다.

대역폭 테스트는 기본적으로 [getbar](https://github.com/lenik/getbar)를 사용합니다. `lrm(1)` 참고.

문서: `doc/README-ko.md`, 매뉴얼 `man/ko/man1/lrm.1`.

## 저장소 구조

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

## 로그 및 색상

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

## 국제화(gettext)

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE=ko ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

## 빌드 및 설치

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

## Debian 패키징

```bash
dpkg-buildpackage -us -uc
```

## 라이선스

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
