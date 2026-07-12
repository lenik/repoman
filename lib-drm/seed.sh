#!/bin/bash
# Copyright (C) 2026 Lenik <repoman@bodz.net>
# SPDX-License-Identifier: AGPL-3.0-or-later

seed_default_mirrors() {
    mirror_add docker 10 https://registry-1.docker.io
    mirror_add ustc 20 https://docker.mirrors.ustc.edu.cn
    mirror_add 163 25 https://hub-mirror.c.163.com
    mirror_add daocloud 30 https://docker.m.daocloud.io
    mirror_add baidu 35 https://mirror.baidubce.com
    mirror_add nju 40 https://docker.nju.edu.cn
}

ensure_mirrors() {
    if [[ -f "$DRM_MIRROR_FILE" ]]; then
        load_mirrors
        return 0
    fi

    seed_default_mirrors
    save_mirrors
    DRM_MIRRORS_LOADED=1
    vlog "$(_ 'installed default Docker registry mirrors')"
}
