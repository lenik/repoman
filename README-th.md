# repoman

**repoman** จัดหา **lrm** (ตัวจัดการ repo ของ Linux): เครื่องมือ Bash สำหรับจัดการ
ทดสอบ และนำมิเรอร์แพ็กเกจ (apt, dnf/yum, pacman) ไปใช้

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

นิยามมิเรอร์อยู่ที่ `$XDG_CONFIG_HOME/repoman/lrm/` รันครั้งแรกจะใส่ค่าเริ่มต้น
ตามครอบครัวดิสโทรที่ตรวจพบ (Debian, RPM หรือ Arch)

การทดสอบแบนด์วิดท์ใช้ [getbar](https://github.com/lenik/getbar) ค่าเริ่มต้น
`-c -d2 -p1 -w3 -s30m -i.1 -q` ดูรายละเอียดใน `lrm(1)`

## โครงสร้างที่เก็บ

- `lrm.in` — สคริปต์หลัก (Meson สร้าง `build/lrm`)
- `lib/` — โมดูลแบ็กเอนด์ (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — แคตตาล็อก gettext (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — คู่มือแต่ละภาษา (ดูแลด้วยมือ)
- `README-<lang>.md` — README แต่ละภาษา (ดูแลด้วยมือ)
- `lrm.1.in` — ต้นฉบับคู่มือภาษาอังกฤษ
- `debian/` — ข้อมูลแพ็กเกจ Debian
- `meson.build` — นิยาม build ระดับบน

## บันทึกและสี

เมื่อ stderr เป็น TTY และมี terminfo จะใส่สีตามระดับ (`tput` ก่อน แล้ว ANSI):

| ระดับ | แฟล็ก | สี (โดยทั่วไป) | เนื้อหา |
|-------|-------|----------------|---------|
| 0 | (ค่าเริ่มต้น) | เขียว | ความคืบหน้าปกติ |
| 1 | `-v` | ฟ้า | ทดสอบแต่ละมิเรอร์ |
| 2 | `-vv` | น้ำเงิน | เส้นทาง, sudo, ดิสโทร |
| 3 | `-vvv` | ม่วงแดง | ค่าวัด, คำสั่ง |
| 4 | `-vvvv` | จาง | ผลเครื่องมือภายนอก |
| warn | — | เหลือง | คำเตือน |
| err | — | แดงหนา | ข้อผิดพลาด |

ใช้ `-q` เพื่อกดทุกอย่างยกเว้นข้อผิดพลาด

## การแปลภาษา

### ข้อความ CLI (gettext)

โดเมนข้อความ `lrm` ค้นหาแคตตาล็อกตามลำดับ: `po/` ต้นทาง, `build/po/`, `$(localedir)`

```bash
LANGUAGE=th ./build/lrm -h
```

Meson คอมไพล์ `po/*.po` เป็น `*.mo` ตอน build (เหมือน getbar)

### คู่มือและ README (แปลด้วยมือ)

ต้นฉบับอังกฤษ: `README.md`, `lrm.1.in` แก้ `README-<lang>.md` และ
`man/<lang>/lrm.1.in` โดยตรง `<lang>` ต้องตรงกับ `po/LINGUAS` ดู `po/TRANSLATORS.md`

## สร้างและติดตั้ง

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

รันไทม์เสริม: **getbar**, **iputils-ping**

## แพ็กเกจ Debian

```bash
dpkg-buildpackage -us -uc
```

## สัญญาอนุญาต

Copyright (C) 2026 Lenik <repoman@bodz.net>

ภายใต้ **AGPL-3.0-or-later**
