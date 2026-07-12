# repoman

**repoman** 提供 **lrm**（Linux 软件源管理器）：一个 Bash 工具，用于管理、
测速并应用各发行版的软件包镜像（apt、dnf/yum、pacman）。

## `lrm` 快速上手

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

镜像配置保存在 `$XDG_CONFIG_HOME/repoman/lrm/`。首次运行时，会根据检测到的
发行版族（Debian、RPM 或 Arch）写入内置默认镜像。

带宽测试默认使用 [getbar](https://github.com/lenik/getbar)，参数为
`-c -d2 -p1 -w3 -s30m -i.1 -q`。完整命令说明与评分算法见 `lrm(1)`。

## 仓库结构

- `lrm.in` — 主程序（Meson 生成 `build/lrm`）
- `lib/` — 后端模块（`common.sh`、`debian.sh`、`rpm.sh`、`arch.sh` 等）
- `po/` — gettext 消息目录（`*.po` → `*.mo`）
- `man/<lang>/lrm.1.in` — 各语言手册页（手工维护）
- `README-<lang>.md` — 各语言说明（手工维护）
- `lrm.1.in` — 英文手册页源文件
- `debian/` — Debian 打包元数据
- `meson.build` — 顶层构建定义

## 日志与颜色

当标准错误输出为终端且 terminfo 可用时，`lrm` 会按日志级别着色（优先
`tput`，否则回退 ANSI）：

| 级别 | 选项 | 颜色（典型） | 内容 |
|------|------|--------------|------|
| 0 | （默认） | 绿色 | 常规进度 |
| 1 | `-v` | 青色 | 各镜像测试 |
| 2 | `-vv` | 蓝色 | 路径、sudo、发行版 |
| 3 | `-vvv` | 洋红 | 测量值与命令 |
| 4 | `-vvvv` | 灰色 | 外部工具输出 |
| warn | — | 黄色 | 警告 |
| err | — | 粗体红 | 错误 |

使用 `-q` 可抑制除错误外的输出。

## 国际化

### CLI 消息（gettext）

用户可见字符串使用 gettext，文本域为 `lrm`。运行时按以下顺序查找
消息目录：

1. **源码目录** — 项目下的 `po/`
2. **构建目录** — `ninja` 编译后的 `build/po/`
3. **安装前缀** — `$(localedir)`（默认 `/usr/share/locale`）

```bash
LANGUAGE=zh_CN ./build/lrm -h
```

`po/*.po` 由 Meson 在构建时编译为 `*.mo`（与 getbar 相同，无单独 sync 目标）。

### 手册与 README（手工翻译）

英文原文：`README.md`、`lrm.1.in`。

其它语言由译者**直接编辑**源文件，不使用自动生成脚本：

- `README-<lang>.md`
- `man/<lang>/lrm.1.in`（安装为 `man/<lang>/man1/lrm.1`）

`<lang>` 须与 `po/LINGUAS` 中的 locale 名一致。修改英文原文后，请手工
更新各语言译文。

## 构建与安装

### 构建依赖

```bash
sudo apt install meson ninja-build gettext
```

`lrm bwtest` 可选运行时依赖：**getbar**、**iputils-ping**。

### 配置并构建

使用绝对构建目录 `/build`：

```bash
meson setup /build
ninja -C /build
meson install -C /build
```

调试符号链接：

```bash
ninja -C /build install-symlinks
ninja -C /build uninstall-symlinks
```

## Debian 打包

```bash
dpkg-buildpackage -us -uc
```

## 许可证

Copyright (C) 2026 Lenik <repoman@bodz.net>

采用 **AGPL-3.0-or-later** 许可。
