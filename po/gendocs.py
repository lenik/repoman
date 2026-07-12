#!/usr/bin/env python3
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Generate translated README and man page sources for po/LINGUAS."""

from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
PO = ROOT / "po"
DOC = ROOT / "doc"

LANGS = [line.strip() for line in (PO / "LINGUAS").read_text().splitlines()
         if line.strip() and not line.startswith("#")]

# Shared man body (troff); only header labels and prose differ per language.
MAN_USE_DEBIAN = r""".TP
.BR use " [" \-c ", " \-\-config\-only "] [" apply opts "] " ALIAS\|NUM
{use_intro}
.PP
{debian_intro}
.BR main ", " contrib ", " non-free ", " non-free-firmware
{debian_components}
.BR deb\-src ,
{debian_tail}
.BR \-a ", " \-\-all ", " \-s ", " \-\-src ", " \-u ", " \-\-updates ", " \-b ", " \-\-backports ", " \-\-security ", " \-\-suite .
.PP
{rpm_intro}
.BR \-e ", " \-\-everything
{rpm_everything}
.BR \-E ", " \-\-epel
{rpm_epel}
.BR \-a ", " \-\-all
{rpm_all}
.BR \-\-releasever ", " \-\-arch ", " \-\-appstream ", " \-\-crb ", " \-\-powertools ", " \-\-minimal .
{same_apply}
.PP
{config_only}
.I /etc/apt/sources.list.d/lrm.sources
{without_apt}
.BR apt\-get " update".
{use_num}"""

META = {
    "zh_CN": {
        "man_section": "用户命令",
        "name_h": "名称", "synopsis_h": "概要", "description_h": "描述",
        "options_h": "选项", "commands_h": "命令", "i18n_h": "国际化",
        "files_h": "文件", "examples_h": "示例", "author_h": "作者", "copyright_h": "版权",
        "name": "lrm \\- 管理与测速 Linux 发行版软件源镜像",
        "option": "选项", "command": "命令", "args": "参数",
        "desc": ("保存镜像别名与 URL，通过 ping 或 HTTP 下载测试进行测速，并将所选镜像应用到本地\n"
                 "包管理器配置。支持的发行版族由\n.BR /etc/os-release\n检测：Debian/Ubuntu（apt）、RHEL 系（dnf/yum）、Arch（pacman）。"),
        "mirror_store": ("镜像定义保存在\n.RI $XDG_CONFIG_HOME /repoman/lrm/ 。\n"
                         "首次运行且该目录尚不存在时，\n.B lrm\n会为检测到的发行版族（Debian、RPM 或 Arch）写入内置默认镜像。"),
        "verbose": ("提高日志详细程度，可重复\n.RB ( \\-vv \", \" \\-vvv \", \" \\-vvvv ) ：\n"
                    "1 级记录各镜像测试，2 级记录路径与权限提升，3 级记录测量值与命令，4 级记录外部工具输出。\n"
                    "当标准错误为终端且 terminfo 可用时，按级别着色（绿色进度、青/蓝/洋红/灰色详细、黄色警告、红色错误）。"),
        "quiet": "减少日志输出。", "help": "显示用法摘要并退出。", "version": "显示版本信息并退出。",
        "list": ("列出已配置镜像，格式为\n.IR 标记 \" [\" N \"] \" 别名 。\n"
                 "标记为\n.BR * \"（已选）、\" \\- \"（上次测试失败）、\" ? \"（未测试）或两空格。\n"
                 ".RB N\n为\n.BR use \" 与 \" remove\n接受的一基序号。加\n.BR \\-p \" 或 \" \\-\\-priority\n时同时显示优先级与 URL。"),
        "add": ("添加或更新镜像。优先级可用\n.BR \\- N\n写在别名前，或用\n.BR \\-p\n指定（默认 100，数值越小在列表中越靠前）。"),
        "remove": "按别名或列表序号移除镜像。",
        "use_intro": "设置默认镜像并应用到系统包管理器。",
        "debian_intro": "Debian 应用选项（默认\n.BR \\-\\-all ):",
        "debian_components": "组件、", "debian_tail": "suite-updates、backports 与 security 条目。标志包括",
        "rpm_intro": "RPM 应用选项（默认仅 BaseOS）：",
        "rpm_everything": "启用 BaseOS、AppStream 与 CRB/PowerTools；",
        "rpm_epel": "添加 EPEL；", "rpm_all": "启用全部并包含 EPEL。另有",
        "same_apply": "相同的应用选项也适用于\n.BR pingsel \" 与 \" bwsel 。",
        "config_only": "使用\n.B \\-\\-config\\-only\n仅写入",
        "without_apt": "，不运行", "use_num": "可使用列表序号（如\n.B 3\n）或别名（如\n.BR tuna ）。",
        "pingtest": "并行 ping 各镜像主机，按延迟与丢包率排序（默认次数 3，超时 2 秒）。",
        "bwtest": ("使用\n.BR getbar (1)\n并行从各镜像下载元数据文件并按得分排序。默认对探测 URL 运行\n"
                   ".RB getbar \" -c -d2 -p1 -w3 -s30m -i.1 -q\"。\n"
                   "得分按 3 MiB 参考文件的等效字节/秒计算，可用\n.BR \\-\\-ref\n或\n.IR LRM_BWTEST_REF_BYTES\n覆盖参考大小。"),
        "pingsel": "执行\n.B pingtest\n并应用最佳镜像（与\n.BR use \" 相同的应用选项）。",
        "bwsel": "执行\n.B bwtest\n并应用最佳镜像（与\n.BR use \" 相同的应用选项）。",
        "help_cmd": "显示用法。", "version_cmd": "显示版本。",
        "i18n": ("用户可见消息使用 gettext（文本域\n.BR lrm ）。\n"
                 "消息目录按源码\n.I po/\n、构建目录、安装 locale 目录顺序查找。通过\n"
                 ".BR LANGUAGE \"、\" LC_ALL \" 或 \" LANG\n选择语言（如\n.BR zh_CN ）。"),
        "license": "许可证 AGPL-3.0-or-later。",
        "ex_add": "添加镜像并列出：", "ex_bw": "测速并选择最快镜像：",
    },
    "zh_TW": {
        "man_section": "使用者命令",
        "name_h": "名稱", "synopsis_h": "概要", "description_h": "描述",
        "options_h": "選項", "commands_h": "命令", "i18n_h": "國際化",
        "files_h": "檔案", "examples_h": "範例", "author_h": "作者", "copyright_h": "版權",
        "name": "lrm \\- 管理與測速 Linux 發行版軟體源鏡像",
        "option": "選項", "command": "命令", "args": "參數",
        "desc": ("儲存鏡像別名與 URL，透過 ping 或 HTTP 下載測試進行測速，並將所選鏡像套用到本機\n"
                 "套件管理器設定。支援的發行版族由\n.BR /etc/os-release\n偵測：Debian/Ubuntu（apt）、RHEL 系（dnf/yum）、Arch（pacman）。"),
        "mirror_store": ("鏡像定義儲存在\n.RI $XDG_CONFIG_HOME /repoman/lrm/ 。\n"
                         "首次執行且該目錄尚不存在時，\n.B lrm\n會為偵測到的發行版族（Debian、RPM 或 Arch）寫入內建預設鏡像。"),
        "verbose": ("提高日誌詳細程度，可重複\n.RB ( \\-vv \", \" \\-vvv \", \" \\-vvvv ) ：\n"
                    "1 級記錄各鏡像測試，2 級記錄路徑與權限提升，3 級記錄測量值與命令，4 級記錄外部工具輸出。\n"
                    "當標準錯誤為終端且 terminfo 可用時，依級別著色。"),
        "quiet": "減少日誌輸出。", "help": "顯示用法摘要並結束。", "version": "顯示版本資訊並結束。",
        "list": ("列出已設定鏡像，格式為\n.IR 標記 \" [\" N \"] \" 別名 。\n"
                 "標記為\n.BR * \"（已選）、\" \\- \"（上次測試失敗）、\" ? \"（未測試）或兩空格。"),
        "add": "新增或更新鏡像（預設優先順序 100，數值越小越靠前）。",
        "remove": "依別名或列表序號移除鏡像。",
        "use_intro": "設定預設鏡像並套用到系統套件管理器。",
        "debian_intro": "Debian 套用選項（預設\n.BR \\-\\-all ):",
        "debian_components": "元件、", "debian_tail": "suite-updates、backports 與 security 項目。旗標包括",
        "rpm_intro": "RPM 套用選項（預設僅 BaseOS）：",
        "rpm_everything": "啟用 BaseOS、AppStream 與 CRB/PowerTools；",
        "rpm_epel": "新增 EPEL；", "rpm_all": "啟用全部並包含 EPEL。另有",
        "same_apply": "相同的套用選項亦適用於\n.BR pingsel \" 與 \" bwsel 。",
        "config_only": "使用\n.B \\-\\-config\\-only\n僅寫入",
        "without_apt": "，不執行", "use_num": "可使用列表序號或別名。",
        "pingtest": "並行 ping 各鏡像主機，依延遲與丟包率排序（預設 3 次，逾時 2 秒）。",
        "bwtest": "使用\n.BR getbar (1)\n並行下載測試並依得分排序。",
        "pingsel": "執行\n.B pingtest\n並套用最佳鏡像（與\n.BR use \" 相同套用選項）。",
        "bwsel": "執行\n.B bwtest\n並套用最佳鏡像（與\n.BR use \" 相同套用選項）。",
        "help_cmd": "顯示用法。", "version_cmd": "顯示版本。",
        "i18n": "使用者可見訊息使用 gettext（文字域\n.BR lrm ）。透過\n.BR LANGUAGE \"、\" LC_ALL \" 或 \" LANG\n選擇語言。",
        "license": "授權條款 AGPL-3.0-or-later。",
        "ex_add": "新增鏡像並列出：", "ex_bw": "測速並選擇最快鏡像：",
    },
    "ja": {
        "man_section": "ユーザーコマンド",
        "name_h": "名前", "synopsis_h": "概要", "description_h": "説明",
        "options_h": "オプション", "commands_h": "コマンド", "i18n_h": "国際化",
        "files_h": "ファイル", "examples_h": "例", "author_h": "作者", "copyright_h": "著作権",
        "name": "lrm \\- Linux ディストリビューションのパッケージミラーを管理・ベンチマークする",
        "option": "オプション", "command": "コマンド", "args": "引数",
        "desc": (".B lrm\nはミラー別名と URL を保持し、ping または HTTP ダウンロードテストでベンチマークし、"
                 "選択したミラーをローカルのパッケージマネージャー設定に適用します。"
                 "対応ディストリビューション族は\n.BR /etc/os-release\nから検出します。"),
        "mirror_store": "ミラー定義は\n.RI $XDG_CONFIG_HOME /repoman/lrm/ に保存されます。初回実行時に既定ミラーを作成します。",
        "verbose": "ログ詳細度を上げます（\\-vv まで繰り返し可）。端末ではレベル別に色付けされます。",
        "quiet": "ログ出力を減らします。", "help": "用法を表示して終了します。", "version": "バージョン情報を表示して終了します。",
        "list": "設定済みミラーを MARK [N] ALIAS 形式で一覧表示します。",
        "add": "ミラーを追加または更新します（既定優先度 100）。",
        "remove": "別名または一覧番号でミラーを削除します。",
        "use_intro": "既定ミラーを設定しシステムに適用します。",
        "debian_intro": "Debian 適用オプション（既定\n.BR \\-\\-all ):",
        "debian_components": "コンポーネント、", "debian_tail": "updates、backports、security など。フラグ:",
        "rpm_intro": "RPM 適用オプション（既定は BaseOS のみ）:",
        "rpm_everything": "BaseOS、AppStream、CRB/PowerTools を有効化;",
        "rpm_epel": "EPEL を追加;", "rpm_all": "すべてと EPEL を有効化。その他",
        "same_apply": "同じ適用オプションは\n.BR pingsel \" と \" bwsel \" でも使えます。",
        "config_only": "使用\n.B \\-\\-config\\-only\nは",
        "without_apt": "のみ書き込み、", "use_num": "一覧番号または別名を指定できます。",
        "pingtest": "各ミラーを並列 ping し遅延順に表示します（既定 3 回、タイムアウト 2 秒）。",
        "bwtest": ".BR getbar (1)\nで並列ダウンロードテストしスコア順に表示します。",
        "pingsel": ".B pingtest\nを実行し最良ミラーを適用します（\n.BR use \" と同じ適用オプション）。",
        "bwsel": ".B bwtest\nを実行し最良ミラーを適用します（\n.BR use \" と同じ適用オプション）。",
        "help_cmd": "用法を表示します。", "version_cmd": "バージョンを表示します。",
        "i18n": "gettext（ドメイン\n.BR lrm ）を使用します。\n.BR LANGUAGE \"、\" LANG\nなどで言語を選択します。",
        "license": "ライセンス AGPL-3.0-or-later。",
        "ex_add": "ミラーを追加して一覧:", "ex_bw": "ベンチマークして最速を選択:",
    },
    "ko": {
        "man_section": "사용자 명령",
        "name_h": "이름", "synopsis_h": "개요", "description_h": "설명",
        "options_h": "옵션", "commands_h": "명령", "i18n_h": "국제화",
        "files_h": "파일", "examples_h": "예제", "author_h": "저자", "copyright_h": "저작권",
        "name": "lrm \\- Linux 배포판 패키지 미러 관리 및 벤치마크",
        "option": "옵션", "command": "명령", "args": "인수",
        "desc": "미러 별칭과 URL을 저장하고 ping 또는 HTTP 다운로드 테스트로 벤치마크한 뒤 패키지 관리자에 적용합니다.",
        "mirror_store": "미러 정의는\n.RI $XDG_CONFIG_HOME /repoman/lrm/ 에 저장됩니다.",
        "verbose": "로그 상세도를 높입니다. 터미널에서는 수준별 색상을 사용합니다.",
        "quiet": "로그 출력을 줄입니다.", "help": "도움말을 표시하고 종료합니다.", "version": "버전 정보를 표시하고 종료합니다.",
        "list": "설정된 미러를 MARK [N] ALIAS 형식으로 나열합니다.",
        "add": "미러를 추가하거나 갱신합니다(기본 우선순위 100).",
        "remove": "별칭 또는 목록 번호로 미러를 제거합니다.",
        "use_intro": "기본 미러를 설정하고 시스템에 적용합니다.",
        "debian_intro": "Debian 적용 옵션(기본\n.BR \\-\\-all ):",
        "debian_components": "구성 요소,", "debian_tail": "updates, backports, security 등. 플래그:",
        "rpm_intro": "RPM 적용 옵션(기본 BaseOS만):",
        "rpm_everything": "BaseOS, AppStream, CRB/PowerTools 활성화;",
        "rpm_epel": "EPEL 추가;", "rpm_all": "전체 및 EPEL 활성화. 또한",
        "same_apply": "동일한 적용 옵션을\n.BR pingsel \" 및 \" bwsel \" 에서도 사용합니다.",
        "config_only": "사용\n.B \\-\\-config\\-only\n는",
        "without_apt": "만 쓰고", "use_num": "목록 번호 또는 별칭을 사용할 수 있습니다.",
        "pingtest": "미러를 병렬 ping하고 지연 순으로 표시합니다(기본 3회, 제한 2초).",
        "bwtest": ".BR getbar (1)\n로 병렬 다운로드 테스트 후 점수 순으로 표시합니다.",
        "pingsel": ".B pingtest\n후 최적 미러 적용(\n.BR use \" 와 동일 옵션).",
        "bwsel": ".B bwtest\n후 최적 미러 적용(\n.BR use \" 와 동일 옵션).",
        "help_cmd": "도움말 표시.", "version_cmd": "버전 표시.",
        "i18n": "gettext(도메인\n.BR lrm ) 사용.\n.BR LANGUAGE\n등으로 언어 선택.",
        "license": "라이선스 AGPL-3.0-or-later.",
        "ex_add": "미러 추가 및 목록:", "ex_bw": "벤치마크 후 최적 선택:",
    },
    "fr": {
        "man_section": "Commandes utilisateur",
        "name_h": "NOM", "synopsis_h": "SYNOPSIS", "description_h": "DESCRIPTION",
        "options_h": "OPTIONS", "commands_h": "COMMANDES", "i18n_h": "INTERNATIONALISATION",
        "files_h": "FICHIERS", "examples_h": "EXEMPLES", "author_h": "AUTEUR", "copyright_h": "COPYRIGHT",
        "name": "lrm \\- gérer et évaluer les miroirs de dépôts Linux",
        "option": "OPTION", "command": "COMMANDE", "args": "ARGUMENTS",
        "desc": "Stocke alias et URL de miroirs, les évalue par ping ou téléchargement HTTP, puis applique le miroir choisi.",
        "mirror_store": "Les miroirs sont stockés sous\n.RI $XDG_CONFIG_HOME /repoman/lrm/ .",
        "verbose": "Augmente la verbosité des journaux (répétable). Couleurs par niveau sur terminal.",
        "quiet": "Réduit les journaux.", "help": "Affiche l'aide et quitte.", "version": "Affiche la version et quitte.",
        "list": "Liste les miroirs sous la forme MARK [N] ALIAS.",
        "add": "Ajoute ou met à jour un miroir (priorité 100 par défaut).",
        "remove": "Supprime un miroir par alias ou numéro.",
        "use_intro": "Définit le miroir par défaut et l'applique au système.",
        "debian_intro": "Options Debian (défaut\n.BR \\-\\-all ):",
        "debian_components": "composants,", "debian_tail": "updates, backports, security. Options:",
        "rpm_intro": "Options RPM (BaseOS seul par défaut):",
        "rpm_everything": "active BaseOS, AppStream et CRB/PowerTools;",
        "rpm_epel": "ajoute EPEL;", "rpm_all": "tout active y compris EPEL. Aussi",
        "same_apply": "Les mêmes options s'appliquent à\n.BR pingsel \" et \" bwsel .",
        "config_only": "Avec\n.B \\-\\-config\\-only\nécrit seulement",
        "without_apt": "sans lancer", "use_num": "Numéro de liste ou alias accepté.",
        "pingtest": "Ping parallèle trié par latence (3 essais, 2 s par défaut).",
        "bwtest": "Test de téléchargement parallèle via\n.BR getbar (1), tri par score.",
        "pingsel": "Lance\n.B pingtest\net applique le meilleur miroir (options comme\n.BR use ).",
        "bwsel": "Lance\n.B bwtest\net applique le meilleur miroir (options comme\n.BR use ).",
        "help_cmd": "Affiche l'aide.", "version_cmd": "Affiche la version.",
        "i18n": "Messages via gettext (domaine\n.BR lrm ). Langue avec\n.BR LANGUAGE \" ou \" LANG .",
        "license": "Licence AGPL-3.0-or-later.",
        "ex_add": "Ajouter et lister:", "ex_bw": "Mesurer et choisir le plus rapide:",
    },
    "de": {
        "man_section": "Benutzerbefehle",
        "name_h": "NAME", "synopsis_h": "ÜBERSICHT", "description_h": "BESCHREIBUNG",
        "options_h": "OPTIONEN", "commands_h": "BEFEHLE", "i18n_h": "INTERNATIONALISIERUNG",
        "files_h": "DATEIEN", "examples_h": "BEISPIELE", "author_h": "AUTOR", "copyright_h": "COPYRIGHT",
        "name": "lrm \\- Linux-Paketspiegel verwalten und testen",
        "option": "OPTION", "command": "BEFEHL", "args": "ARGUMENTE",
        "desc": "Speichert Spiegel-Aliase und URLs, testet per Ping oder HTTP-Download und wendet den gewählten Spiegel an.",
        "mirror_store": "Spiegeldefinitionen unter\n.RI $XDG_CONFIG_HOME /repoman/lrm/ .",
        "verbose": "Erhöht Protokollierung (wiederholbar). Farben pro Stufe am Terminal.",
        "quiet": "Weniger Protokollausgabe.", "help": "Hilfe anzeigen und beenden.", "version": "Version anzeigen und beenden.",
        "list": "Listet Spiegel als MARK [N] ALIAS.",
        "add": "Spiegel hinzufügen oder aktualisieren (Priorität 100).",
        "remove": "Spiegel per Alias oder Listennummer entfernen.",
        "use_intro": "Standardspiegel setzen und anwenden.",
        "debian_intro": "Debian-Optionen (Standard\n.BR \\-\\-all ):",
        "debian_components": "Komponenten,", "debian_tail": "updates, backports, security. Flags:",
        "rpm_intro": "RPM-Optionen (Standard nur BaseOS):",
        "rpm_everything": "aktiviert BaseOS, AppStream und CRB/PowerTools;",
        "rpm_epel": "fügt EPEL hinzu;", "rpm_all": "alles inkl. EPEL. Auch",
        "same_apply": "Dieselben Optionen gelten für\n.BR pingsel \" und \" bwsel .",
        "config_only": "Mit\n.B \\-\\-config\\-only\nnur",
        "without_apt": "schreiben ohne", "use_num": "Listennummer oder Alias möglich.",
        "pingtest": "Paralleler Ping, sortiert nach Latenz (3 Zähler, 2 s Timeout).",
        "bwtest": "Paralleler Download-Test mit\n.BR getbar (1), sortiert nach Score.",
        "pingsel": "Führt\n.B pingtest\naus und wendet besten Spiegel an (wie\n.BR use ).",
        "bwsel": "Führt\n.B bwtest\naus und wendet besten Spiegel an (wie\n.BR use ).",
        "help_cmd": "Hilfe anzeigen.", "version_cmd": "Version anzeigen.",
        "i18n": "gettext (Domäne\n.BR lrm ). Sprache via\n.BR LANGUAGE \" oder \" LANG .",
        "license": "Lizenz AGPL-3.0-or-later.",
        "ex_add": "Spiegel hinzufügen und auflisten:", "ex_bw": "Testen und schnellsten wählen:",
    },
    "it": {
        "man_section": "Comandi utente",
        "name_h": "NOME", "synopsis_h": "SINTESI", "description_h": "DESCRIZIONE",
        "options_h": "OPZIONI", "commands_h": "COMANDI", "i18n_h": "INTERNAZIONALIZZAZIONE",
        "files_h": "FILE", "examples_h": "ESEMPI", "author_h": "AUTORE", "copyright_h": "COPYRIGHT",
        "name": "lrm \\- gestire e valutare mirror di repository Linux",
        "option": "OPZIONE", "command": "COMANDO", "args": "ARGOMENTI",
        "desc": "Memorizza alias e URL dei mirror, li valuta con ping o download HTTP e applica il mirror scelto.",
        "mirror_store": "I mirror sono in\n.RI $XDG_CONFIG_HOME /repoman/lrm/ .",
        "verbose": "Aumenta la verbosità (ripetibile). Colori per livello su terminale.",
        "quiet": "Riduce i log.", "help": "Mostra l'aiuto e termina.", "version": "Mostra la versione e termina.",
        "list": "Elenca i mirror come MARK [N] ALIAS.",
        "add": "Aggiunge o aggiorna un mirror (priorità 100).",
        "remove": "Rimuove un mirror per alias o numero.",
        "use_intro": "Imposta il mirror predefinito e lo applica al sistema.",
        "debian_intro": "Opzioni Debian (default\n.BR \\-\\-all ):",
        "debian_components": "componenti,", "debian_tail": "updates, backports, security. Flag:",
        "rpm_intro": "Opzioni RPM (solo BaseOS di default):",
        "rpm_everything": "abilita BaseOS, AppStream e CRB/PowerTools;",
        "rpm_epel": "aggiunge EPEL;", "rpm_all": "tutto incluso EPEL. Anche",
        "same_apply": "Le stesse opzioni valgono per\n.BR pingsel \" e \" bwsel .",
        "config_only": "Con\n.B \\-\\-config\\-only\nscrive solo",
        "without_apt": "senza eseguire", "use_num": "Numero elenco o alias.",
        "pingtest": "Ping parallelo ordinato per latenza (3 tentativi, timeout 2 s).",
        "bwtest": "Test download parallelo con\n.BR getbar (1), ordinato per punteggio.",
        "pingsel": "Esegue\n.B pingtest\ne applica il miglior mirror (opzioni come\n.BR use ).",
        "bwsel": "Esegue\n.B bwtest\ne applica il miglior mirror (opzioni come\n.BR use ).",
        "help_cmd": "Mostra l'aiuto.", "version_cmd": "Mostra la versione.",
        "i18n": "gettext (dominio\n.BR lrm ). Lingua con\n.BR LANGUAGE \" o \" LANG .",
        "license": "Licenza AGPL-3.0-or-later.",
        "ex_add": "Aggiungere e elencare:", "ex_bw": "Testare e scegliere il più veloce:",
    },
    "vi": {
        "man_section": "Lệnh người dùng",
        "name_h": "TÊN", "synopsis_h": "TÓM TẮT", "description_h": "MÔ TẢ",
        "options_h": "TÙY CHỌN", "commands_h": "LỆNH", "i18n_h": "QUỐC TẾ HÓA",
        "files_h": "TỆP", "examples_h": "VÍ DỤ", "author_h": "TÁC GIẢ", "copyright_h": "BẢN QUYỀN",
        "name": "lrm \\- quản lý và đo tốc độ mirror kho phần mềm Linux",
        "option": "TÙY CHỌN", "command": "LỆNH", "args": "ĐỐI SỐ",
        "desc": "Lưu bí danh và URL mirror, đo bằng ping hoặc tải HTTP, rồi áp mirror đã chọn.",
        "mirror_store": "Mirror lưu tại\n.RI $XDG_CONFIG_HOME /repoman/lrm/ .",
        "verbose": "Tăng mức log (lặp được). Màu theo mức trên terminal.",
        "quiet": "Giảm log.", "help": "Hiện trợ giúp và thoát.", "version": "Hiện phiên bản và thoát.",
        "list": "Liệt kê mirror dạng MARK [N] ALIAS.",
        "add": "Thêm hoặc cập nhật mirror (ưu tiên 100).",
        "remove": "Xóa mirror theo bí danh hoặc số thứ tự.",
        "use_intro": "Đặt mirror mặc định và áp vào hệ thống.",
        "debian_intro": "Tùy chọn Debian (mặc định\n.BR \\-\\-all ):",
        "debian_components": "thành phần,", "debian_tail": "updates, backports, security. Cờ:",
        "rpm_intro": "Tùy chọn RPM (mặc định chỉ BaseOS):",
        "rpm_everything": "bật BaseOS, AppStream và CRB/PowerTools;",
        "rpm_epel": "thêm EPEL;", "rpm_all": "bật tất cả kèm EPEL. Cũng",
        "same_apply": "Cùng tùy chọn áp dụng cho\n.BR pingsel \" và \" bwsel .",
        "config_only": "Dùng\n.B \\-\\-config\\-only\nchỉ ghi",
        "without_apt": "không chạy", "use_num": "Dùng số thứ tự hoặc bí danh.",
        "pingtest": "Ping song song, sắp theo độ trễ (3 lần, timeout 2 giây).",
        "bwtest": "Tải song song qua\n.BR getbar (1), sắp theo điểm.",
        "pingsel": "Chạy\n.B pingtest\nvà áp mirror tốt nhất (tùy chọn như\n.BR use ).",
        "bwsel": "Chạy\n.B bwtest\nvà áp mirror tốt nhất (tùy chọn như\n.BR use ).",
        "help_cmd": "Hiện trợ giúp.", "version_cmd": "Hiện phiên bản.",
        "i18n": "gettext (miền\n.BR lrm ). Chọn ngôn ngữ bằng\n.BR LANGUAGE \" hoặc \" LANG .",
        "license": "Giấy phép AGPL-3.0-or-later.",
        "ex_add": "Thêm và liệt kê:", "ex_bw": "Đo và chọn nhanh nhất:",
    },
    "th": {
        "man_section": "คำสั่งผู้ใช้",
        "name_h": "ชื่อ", "synopsis_h": "สรุป", "description_h": "คำอธิบาย",
        "options_h": "ตัวเลือก", "commands_h": "คำสั่ง", "i18n_h": "การแปลภาษา",
        "files_h": "ไฟล์", "examples_h": "ตัวอย่าง", "author_h": "ผู้เขียน", "copyright_h": "ลิขสิทธิ์",
        "name": "lrm \\- จัดการและทดสอบมิเรอร์แพ็กเกจ Linux",
        "option": "ตัวเลือก", "command": "คำสั่ง", "args": "อาร์กิวเมนต์",
        "desc": "เก็บชื่อและ URL มิเรอร์ ทดสอบด้วย ping หรือดาวน์โหลด HTTP แล้วนำมิเรอร์ที่เลือกไปใช้",
        "mirror_store": "นิยามมิเรอร์อยู่ที่\n.RI $XDG_CONFIG_HOME /repoman/lrm/ ",
        "verbose": "เพิ่มระดับบันทึก (ทำซ้ำได้) มีสีตามระดับบนเทอร์มินัล",
        "quiet": "ลดบันทึก", "help": "แสดงวิธีใช้และออก", "version": "แสดงเวอร์ชันและออก",
        "list": "แสดงมิเรอร์เป็น MARK [N] ALIAS",
        "add": "เพิ่มหรืออัปเดตมิเรอร์ (ลำดับความสำคัญ 100)",
        "remove": "ลบมิเรอร์ด้วยชื่อหรือหมายเลข",
        "use_intro": "ตั้งมิเรอร์เริ่มต้นและนำไปใช้กับระบบ",
        "debian_intro": "ตัวเลือก Debian (ค่าเริ่มต้น\n.BR \\-\\-all ):",
        "debian_components": "ส่วนประกอบ", "debian_tail": "updates backports security ฯลฯ",
        "rpm_intro": "ตัวเลือก RPM (ค่าเริ่มต้น BaseOS เท่านั้น):",
        "rpm_everything": "เปิด BaseOS AppStream CRB/PowerTools;",
        "rpm_epel": "เพิ่ม EPEL;", "rpm_all": "เปิดทั้งหมดรวม EPEL รวมถึง",
        "same_apply": "ตัวเลือกเดียวกันใช้กับ\n.BR pingsel \" และ \" bwsel ",
        "config_only": "ใช้\n.B \\-\\-config\\-only\nเขียนเฉพาะ",
        "without_apt": "โดยไม่รัน", "use_num": "ใช้หมายเลขหรือชื่อได้",
        "pingtest": "ping ขนาน เรียงตามความหน่วง (3 ครั้ง timeout 2 วินาที)",
        "bwtest": "ทดสอบดาวน์โหลดด้วย\n.BR getbar (1) เรียงตามคะแนน",
        "pingsel": "รัน\n.B pingtest\nแล้วใช้มิเรอร์ที่ดีที่สุด (ตัวเลือกเหมือน\n.BR use )",
        "bwsel": "รัน\n.B bwtest\nแล้วใช้มิเรอร์ที่ดีที่สุด (ตัวเลือกเหมือน\n.BR use )",
        "help_cmd": "แสดงวิธีใช้", "version_cmd": "แสดงเวอร์ชัน",
        "i18n": "gettext (โดเมน\n.BR lrm ) เลือกภาษาด้วย\n.BR LANGUAGE ",
        "license": "สัญญาอนุญาต AGPL-3.0-or-later",
        "ex_add": "เพิ่มและแสดงรายการ:", "ex_bw": "ทดสอบและเลือกที่เร็วที่สุด:",
    },
    "eo": {
        "man_section": "Uzantaj komandoj",
        "name_h": "NOMO", "synopsis_h": "SINTENO", "description_h": "PRISKRIBO",
        "options_h": "OPCIOJ", "commands_h": "KOMANDOJ", "i18n_h": "INTERNACIIGO",
        "files_h": "DOSIEROJ", "examples_h": "EKZEMPLOJ", "author_h": "AŬTORO", "copyright_h": "KOPIRAJTO",
        "name": "lrm \\- administri kaj mezuri spegulojn de Linux-pakaĵoj",
        "option": "OPCIO", "command": "KOMANDO", "args": "ARGUMENTOJ",
        "desc": "Konservas alinomojn kaj URL-ojn de speguloj, mezuras per ping aŭ HTTP-elŝuto, kaj aplikas la elektitan spegulon.",
        "mirror_store": "Speguloj estas en\n.RI $XDG_CONFIG_HOME /repoman/lrm/ .",
        "verbose": "Pli detala protokolo (ripetebla). Koloroj laŭ nivelo sur terminalo.",
        "quiet": "Malpli da protokolo.", "help": "Montri helpon kaj eliri.", "version": "Montri version kaj eliri.",
        "list": "Listigi spegulojn kiel MARK [N] ALIAS.",
        "add": "Aldoni aŭ ĝisdatigi spegulon (prioritato 100).",
        "remove": "Forigi spegulon per alinomo aŭ numero.",
        "use_intro": "Agordi defaŭltan spegulon kaj apliki al la sistemo.",
        "debian_intro": "Debian-aplaj opcioj (defaŭlte\n.BR \\-\\-all ):",
        "debian_components": "komponantoj,", "debian_tail": "updates, backports, security. Flagoj:",
        "rpm_intro": "RPM-aplaj opcioj (defaŭlte nur BaseOS):",
        "rpm_everything": "ebligas BaseOS, AppStream kaj CRB/PowerTools;",
        "rpm_epel": "aldonas EPEL;", "rpm_all": "ĉion inkluzive EPEL. Ankaŭ",
        "same_apply": "La samaj opcioj validas por\n.BR pingsel \" kaj \" bwsel .",
        "config_only": "Kun\n.B \\-\\-config\\-only\nskribas nur",
        "without_apt": "sen lanĉi", "use_num": "Listnumero aŭ alinomo.",
        "pingtest": "Paralela ping ordigita laŭ latenco (3 provoj, 2 s).",
        "bwtest": "Paralela elŝuto-testo per\n.BR getbar (1), ordigita laŭ poentaro.",
        "pingsel": "Rulas\n.B pingtest\nkaj aplikas la plej bonan spegulon (same kiel\n.BR use ).",
        "bwsel": "Rulas\n.B bwtest\nkaj aplikas la plej bonan spegulon (same kiel\n.BR use ).",
        "help_cmd": "Montri helpon.", "version_cmd": "Montri version.",
        "i18n": "gettext (domajno\n.BR lrm ). Lingvo per\n.BR LANGUAGE \" aŭ \" LANG .",
        "license": "Licenco AGPL-3.0-or-later.",
        "ex_add": "Aldoni kaj listigi:", "ex_bw": "Mezuri kaj elekti la plej rapidan:",
    },
}

README_INTRO = {
    "zh_CN": "**repoman** 提供 **lrm**（Linux 软件源管理器）：管理、测速并应用 apt/dnf/yum/pacman 镜像。",
    "zh_TW": "**repoman** 提供 **lrm**（Linux 軟體源管理器）：管理、測速並套用 apt/dnf/yum/pacman 鏡像。",
    "ja": "**repoman** は **lrm**（Linux リポジトリマネージャ）を提供します。apt/dnf/yum/pacman のミラーを管理・測定・適用します。",
    "ko": "**repoman**은 **lrm**(Linux 저장소 관리자)을 제공합니다. apt/dnf/yum/pacman 미러를 관리·벤치마크·적용합니다.",
    "fr": "**repoman** fournit **lrm** (gestionnaire de dépôts Linux) pour gérer, tester et appliquer des miroirs apt/dnf/yum/pacman.",
    "de": "**repoman** liefert **lrm** (Linux-Repo-Manager) zum Verwalten, Testen und Anwenden von apt/dnf/yum/pacman-Spiegeln.",
    "it": "**repoman** fornisce **lrm** (gestore repository Linux) per gestire, testare e applicare mirror apt/dnf/yum/pacman.",
    "vi": "**repoman** cung cấp **lrm** (trình quản lý repo Linux) để quản lý, đo tốc độ và áp mirror apt/dnf/yum/pacman.",
    "th": "**repoman** มี **lrm** (ตัวจัดการ repo ของ Linux) สำหรับจัดการ ทดสอบ และใช้มิเรอร์ apt/dnf/yum/pacman",
    "eo": "**repoman** provizas **lrm** (Linux-depozaj administranto) por administri, mezuri kaj apliki spegulojn apt/dnf/yum/pacman.",
}

README_SECTIONS = {
    "quick": {
        "zh_CN": "## `lrm` 快速上手", "zh_TW": "## `lrm` 快速入門", "ja": "## `lrm` クイックスタート",
        "ko": "## `lrm` 빠른 시작", "fr": "## Démarrage `lrm`", "de": "## `lrm` Schnellstart",
        "it": "## Avvio rapido `lrm`", "vi": "## Bắt đầu `lrm`", "th": "## เริ่มต้น `lrm`", "eo": "## Rapida starto `lrm`",
    },
    "layout": {
        "zh_CN": "## 仓库结构", "zh_TW": "## 倉庫結構", "ja": "## リポジトリ構成", "ko": "## 저장소 구조",
        "fr": "## Structure du dépôt", "de": "## Repository-Struktur", "it": "## Struttura del repository",
        "vi": "## Cấu trúc kho mã", "th": "## โครงสร้างที่เก็บ", "eo": "## Strukturo de la deponejo",
    },
    "logging": {
        "zh_CN": "## 日志与颜色", "zh_TW": "## 日誌與顏色", "ja": "## ログと色", "ko": "## 로그 및 색상",
        "fr": "## Journalisation et couleurs", "de": "## Protokollierung und Farben", "it": "## Log e colori",
        "vi": "## Nhật ký và màu", "th": "## บันทึกและสี", "eo": "## Protokolo kaj koloroj",
    },
    "i18n": {
        "zh_CN": "## 国际化（gettext）", "zh_TW": "## 國際化（gettext）", "ja": "## 国際化（gettext）", "ko": "## 국제화(gettext)",
        "fr": "## Internationalisation (gettext)", "de": "## Internationalisierung (gettext)",
        "it": "## Internazionalizzazione (gettext)", "vi": "## Quốc tế hóa (gettext)",
        "th": "## การแปลภาษา (gettext)", "eo": "## Internaciigo (gettext)",
    },
    "build": {
        "zh_CN": "## 构建与安装", "zh_TW": "## 建置與安裝", "ja": "## ビルドとインストール", "ko": "## 빌드 및 설치",
        "fr": "## Compilation et installation", "de": "## Erstellen und Installieren", "it": "## Compilazione e installazione",
        "vi": "## Biên dịch và cài đặt", "th": "## สร้างและติดตั้ง", "eo": "## Kompilado kaj instalado",
    },
    "debian": {
        "zh_CN": "## Debian 打包", "zh_TW": "## Debian 打包", "ja": "## Debian パッケージ", "ko": "## Debian 패키징",
        "fr": "## Paquet Debian", "de": "## Debian-Paket", "it": "## Pacchetto Debian",
        "vi": "## Gói Debian", "th": "## แพ็กเกจ Debian", "eo": "## Debian-pakaĵo",
    },
    "license": {
        "zh_CN": "## 许可证", "zh_TW": "## 授權條款", "ja": "## ライセンス", "ko": "## 라이선스",
        "fr": "## Licence", "de": "## Lizenz", "it": "## Licenza", "vi": "## Giấy phép",
        "th": "## สัญญาอนุญาต", "eo": "## Licenco",
    },
}


def man_page(lang: str, m: dict) -> str:
    use_block = MAN_USE_DEBIAN.format(**m)
    return f""".TH lrm 1 "@PROJECT_YEAR@" "@PROJECT_VERSION@" "{m['man_section']}"
.SH {m['name_h']}
{m['name']}
.SH {m['synopsis_h']}
.B lrm
.RI [ {m['option']} ]...
.IR {m['command']}
.RI [ {m['args']} ]...
.SH {m['description_h']}
{m['desc']}
.PP
{m['mirror_store']}
.SH {m['options_h']}
.TP
.BR \\-v ", " \\-\\-verbose
{m['verbose']}
.TP
.BR \\-q ", " \\-\\-quiet
{m['quiet']}
.TP
.BR \\-h ", " \\-\\-help
{m['help']}
.TP
.B \\-\\-version
{m['version']}
.SH {m['commands_h']}
.TP
.B list
{m['list']}
.TP
.BR add " [[" \\- PRIORITY "] | " \\-p ", " \\-\\-priority " " N "] " ALIAS URL
{m['add']}
.TP
.BR remove " " ALIAS\\|NUM
{m['remove']}
{use_block}
.TP
.BR pingtest " [" \\-n ", " \\-\\-count " " N "] [" \\-W ", " \\-\\-timeout " " SEC "]"
{m['pingtest']}
.TP
.BR bwtest " [" \\-\\-ref " " BYTES "]"
{m['bwtest']}
.TP
.BR pingsel " [" apply opts "] [" \\-n ", " \\-\\-count " " N "] [" \\-W ", " \\-\\-timeout " " SEC "]"
{m['pingsel']}
.TP
.BR bwsel " [" apply opts "] [" \\-\\-ref " " BYTES "]"
{m['bwsel']}
.TP
.B help
{m['help_cmd']}
.TP
.B version
{m['version_cmd']}
.SH {m['i18n_h']}
{m['i18n']}
.SH {m['files_h']}
.TP
.I ~/.config/repoman/lrm/mirrors
Tab-separated mirror database.
.TP
.I ~/.config/repoman/lrm/default
Currently selected mirror alias.
.TP
.I ~/.config/repoman/lrm/health
Last ping/bwtest result per mirror (
.BR ok " or " bad ).
.TP
.I /etc/apt/sources.list.d/lrm.sources
Applied Debian/Ubuntu mirror (deb822 format).
.TP
.I /etc/yum.repos.d/lrm.repo
Applied RPM-family mirror.
.TP
.I /etc/pacman.d/mirrorlist
Applied Arch mirror list.
.SH {m['examples_h']}
.TP
{m['ex_add']}
.B lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
.br
.B lrm add ustc https://mirrors.ustc.edu.cn/debian
.br
.B lrm list
.TP
{m['ex_bw']}
.B lrm bwsel
.SH {m['author_h']}
@PROJECT_AUTHOR@ <@PROJECT_EMAIL@>
.SH {m['copyright_h']}
Copyright \\(co @PROJECT_YEAR@.
{m['license']}
"""


def readme_body(lang: str) -> str:
    intro = README_INTRO[lang]
    s = README_SECTIONS
    mirror_note = {
        "zh_CN": "镜像配置保存在 `$XDG_CONFIG_HOME/repoman/lrm/`。首次运行会按发行版族写入默认镜像。",
        "zh_TW": "鏡像設定儲存在 `$XDG_CONFIG_HOME/repoman/lrm/`。首次執行會依發行版族寫入預設鏡像。",
        "ja": "ミラーは `$XDG_CONFIG_HOME/repoman/lrm/` に保存されます。初回実行時に既定ミラーを作成します。",
        "ko": "미러는 `$XDG_CONFIG_HOME/repoman/lrm/`에 저장됩니다. 첫 실행 시 기본 미러를 씁니다.",
        "fr": "Les miroirs sont dans `$XDG_CONFIG_HOME/repoman/lrm/`. Au premier lancement, des miroirs par défaut sont créés.",
        "de": "Spiegel liegen unter `$XDG_CONFIG_HOME/repoman/lrm/`. Beim ersten Lauf werden Standardspiegel angelegt.",
        "it": "I mirror sono in `$XDG_CONFIG_HOME/repoman/lrm/`. Al primo avvio vengono creati mirror predefiniti.",
        "vi": "Mirror nằm tại `$XDG_CONFIG_HOME/repoman/lrm/`. Lần chạy đầu sẽ tạo mirror mặc định.",
        "th": "มิเรอร์อยู่ที่ `$XDG_CONFIG_HOME/repoman/lrm/` ครั้งแรกจะสร้างมิเรอร์เริ่มต้น",
        "eo": "Speguloj estas en `$XDG_CONFIG_HOME/repoman/lrm/`. Je unua rulo kreiĝas defaŭltaj speguloj.",
    }[lang]
    getbar_note = {
        "zh_CN": "带宽测试默认使用 [getbar](https://github.com/lenik/getbar)。详见 `lrm(1)`。",
        "zh_TW": "頻寬測試預設使用 [getbar](https://github.com/lenik/getbar)。詳見 `lrm(1)`。",
        "ja": "帯域テストは既定で [getbar](https://github.com/lenik/getbar) を使用。詳細は `lrm(1)`。",
        "ko": "대역폭 테스트는 기본적으로 [getbar](https://github.com/lenik/getbar)를 사용합니다. `lrm(1)` 참고.",
        "fr": "Les tests de bande passante utilisent [getbar](https://github.com/lenik/getbar) par défaut. Voir `lrm(1)`.",
        "de": "Bandbreitentests nutzen standardmäßig [getbar](https://github.com/lenik/getbar). Siehe `lrm(1)`.",
        "it": "I test di banda usano [getbar](https://github.com/lenik/getbar) per default. Vedi `lrm(1)`.",
        "vi": "Thử băng thông mặc định dùng [getbar](https://github.com/lenik/getbar). Xem `lrm(1)`.",
        "th": "ทดสอบแบนด์วิดท์ใช้ [getbar](https://github.com/lenik/getbar) ตามค่าเริ่มต้น ดู `lrm(1)`",
        "eo": "Bandwidth-testoj defaŭlte uzas [getbar](https://github.com/lenik/getbar). Vidu `lrm(1)`.",
    }[lang]
    docs_note = {
        "zh_CN": f"文档：`doc/README-{lang}.md`，手册 `man/{lang}/man1/lrm.1`。",
        "zh_TW": f"文件：`doc/README-{lang}.md`，手冊 `man/{lang}/man1/lrm.1`。",
        "ja": f"ドキュメント: `doc/README-{lang}.md`、マニュアル `man/{lang}/man1/lrm.1`。",
        "ko": f"문서: `doc/README-{lang}.md`, 매뉴얼 `man/{lang}/man1/lrm.1`.",
        "fr": f"Docs : `doc/README-{lang}.md`, manuel `man/{lang}/man1/lrm.1`.",
        "de": f"Doku: `doc/README-{lang}.md`, Handbuch `man/{lang}/man1/lrm.1`.",
        "it": f"Documentazione: `doc/README-{lang}.md`, man `man/{lang}/man1/lrm.1`.",
        "vi": f"Tài liệu: `doc/README-{lang}.md`, man `man/{lang}/man1/lrm.1`.",
        "th": f"เอกสาร: `doc/README-{lang}.md` คู่มือ `man/{lang}/man1/lrm.1`",
        "eo": f"Dokumentado: `doc/README-{lang}.md`, manlibro `man/{lang}/man1/lrm.1`.",
    }[lang]
    return f"""# repoman

{intro}

{s['quick'][lang]}

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

{mirror_note}

{getbar_note}

{docs_note}

{s['layout'][lang]}

- `lrm.in` — driver
- `lib/` — backends (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — gettext catalogs and translated man pages
- `doc/` — translated README files (`README-<lang>.md`)
- `lrm.1.in` — English manual source
- `debian/` — Debian packaging
- `meson.build` — build definition

{s['logging'][lang]}

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

{s['i18n'][lang]}

Text domain `lrm`. Catalog search order: source `po/`, build `build/po/`, install `localedir`.

```bash
LANGUAGE={lang} ./build/lrm -h
```

Sync templates: `ninja -C /build posync`

Translated manuals install to `man/<lang>/man1/lrm.1` for each language in `po/LINGUAS`.

{s['build'][lang]}

```bash
sudo apt install meson ninja-build gettext po4a
meson setup /build
ninja -C /build
meson install -C /build
```

Optional runtime: **getbar**, **iputils-ping**.

{s['debian'][lang]}

```bash
dpkg-buildpackage -us -uc
```

{s['license'][lang]}

Copyright (C) 2026 Lenik <repoman@bodz.net>

Licensed under **AGPL-3.0-or-later**.
"""


def main() -> None:
    DOC.mkdir(exist_ok=True)
    for lang in LANGS:
        if lang not in META:
            raise SystemExit(f"missing META for {lang}")
        man_path = PO / f"lrm.1-{lang}.in"
        man_path.write_text(man_page(lang, META[lang]), encoding="utf-8")
        readme_path = DOC / f"README-{lang}.md"
        readme_path.write_text(readme_body(lang), encoding="utf-8")
        print(f"wrote {man_path.relative_to(ROOT)}")
        print(f"wrote {readme_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
