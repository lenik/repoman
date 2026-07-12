# repoman

**repoman**은 **lrm**(Linux 저장소 관리자)을 제공합니다. apt, dnf/yum, pacman
미러를 관리·벤치마크·적용하는 Bash 도구입니다.

## `lrm` 사용법

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

미러 정의는 `$XDG_CONFIG_HOME/repoman/lrm/`에 저장됩니다. 첫 실행 시
감지된 배포판 계열(Debian, RPM, Arch)에 맞는 기본 미러가 시드됩니다.

대역폭 테스트는 기본적으로 [getbar](https://github.com/lenik/getbar)를
`-c -d2 -p1 -w3 -s30m -i.1 -q`로 사용합니다. 자세한 내용은 `lrm(1)` 참조.

## 저장소 구조

- `lrm.in` — 메인 드라이버(Meson이 `build/lrm` 생성)
- `lib/` — 백엔드 모듈(`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh` 등)
- `po/` — gettext 카탈로그(`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — 언어별 매뉴얼(수동 유지)
- `README-<lang>.md` — 언어별 README(수동 유지)
- `lrm.1.in` — 영어 매뉴얼 원문
- `debian/` — Debian 패키징
- `meson.build` — 최상위 빌드 정의

## 로깅

stderr가 TTY이고 terminfo를 사용할 수 있으면 상세도별 색상(`tput` 우선, ANSI 대체):

| 수준 | 플래그 | 색(일반적) | 내용 |
|------|--------|------------|------|
| 0 | (기본) | 녹색 | 일반 진행 |
| 1 | `-v` | 청록 | 미러별 테스트 |
| 2 | `-vv` | 파랑 | 경로, sudo, 배포판 |
| 3 | `-vvv` | 자홍 | 측정값, 명령 |
| 4 | `-vvvv` | 흐림 | 외부 도구 출력 |
| warn | — | 노랑 | 경고 |
| err | — | 굵은 빨강 | 오류 |

`-q`로 오류 외 출력을 억제할 수 있습니다.

## 국제화

### CLI 메시지(gettext)

텍스트 도메인 `lrm`. 카탈로그 검색 순서: 소스 `po/`, 빌드 `build/po/`,
설치 `$(localedir)`.

```bash
LANGUAGE=ko ./build/lrm -h
```

`po/*.po`는 빌드 시 Meson이 `*.mo`로 컴파일합니다(getbar와 동일).

### 매뉴얼과 README(수동 번역)

영어 원문: `README.md`, `lrm.1.in`. 다른 언어는 `README-<lang>.md`와
`man/<lang>/lrm.1.in`을 직접 편집. `<lang>`은 `po/LINGUAS`와 일치.
`po/TRANSLATORS.md` 참조.

## 빌드 및 설치

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

선택 실행 시 의존성: **getbar**, **iputils-ping**.

## Debian 패키지

```bash
dpkg-buildpackage -us -uc
```

## 라이선스

Copyright (C) 2026 Lenik <repoman@bodz.net>

**AGPL-3.0-or-later** 로 배포됩니다.
