# repoman

**repoman** 提供 **lrm**（Linux 軟體庫管理器）：用於管理、測速並套用各發行版
套件鏡像（apt、dnf/yum、pacman）的 Bash 工具。

## `lrm` 快速上手

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

鏡像設定儲存在 `$XDG_CONFIG_HOME/repoman/lrm/`。首次執行時會依偵測到的
發行版族（Debian、RPM 或 Arch）寫入內建預設鏡像。

頻寬測試預設使用 [getbar](https://github.com/lenik/getbar)，參數為
`-c -d2 -p1 -w3 -s30m -i.1 -q`。完整說明與評分演算法見 `lrm(1)`。

## 倉庫結構

- `lrm.in` — 主程式（Meson 產生 `build/lrm`）
- `lib/` — 後端模組（`common.sh`、`debian.sh`、`rpm.sh`、`arch.sh` 等）
- `po/` — gettext 訊息目錄（`*.po` → `*.mo`）
- `man/<lang>/lrm.1.in` — 各語言手冊頁（手工維護）
- `README-<lang>.md` — 各語言說明（手工維護）
- `lrm.1.in` — 英文手冊頁原文
- `debian/` — Debian 打包中繼資料
- `meson.build` — 頂層建置定義

## 日誌與顏色

當標準錯誤為終端且 terminfo 可用時，依日誌級別著色（優先 `tput`，否則 ANSI）：

| 級別 | 選項 | 顏色（典型） | 內容 |
|------|------|--------------|------|
| 0 | （預設） | 綠色 | 一般進度 |
| 1 | `-v` | 青色 | 各鏡像測試 |
| 2 | `-vv` | 藍色 | 路徑、sudo、發行版 |
| 3 | `-vvv` | 洋紅 | 測量值與命令 |
| 4 | `-vvvv` | 灰色 | 外部工具輸出 |
| warn | — | 黃色 | 警告 |
| err | — | 粗體紅 | 錯誤 |

使用 `-q` 可抑制除錯誤外的輸出。

## 國際化

### CLI 訊息（gettext）

文字域為 `lrm`。訊息目錄查找順序：專案 `po/`、建置 `build/po/`、安裝
`$(localedir)`。

```bash
LANGUAGE=zh_TW ./build/lrm -h
```

`po/*.po` 由 Meson 在构建時編譯為 `*.mo`（與 getbar 相同）。

### 手冊與 README（手工翻譯）

英文原文：`README.md`、`lrm.1.in`。其它語言直接編輯
`README-<lang>.md` 與 `man/<lang>/lrm.1.in`。`<lang>` 須與 `po/LINGUAS`
一致。詳見 `po/TRANSLATORS.md`。

## 建置與安裝

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

可選執行時依賴：**getbar**、**iputils-ping**。

## Debian 打包

```bash
dpkg-buildpackage -us -uc
```

## 授權條款

Copyright (C) 2026 Lenik <repoman@bodz.net>

採用 **AGPL-3.0-or-later** 授權。
