# repoman

**repoman** cung cấp **lrm** (trình quản lý kho Linux): công cụ Bash để quản lý,
đo tốc độ và áp mirror gói phần mềm (apt, dnf/yum, pacman).

## `lrm`

```bash
lrm list
lrm add -10 tuna https://mirrors.tuna.tsinghua.edu.cn/debian
lrm pingtest
lrm bwsel
```

Định nghĩa mirror nằm tại `$XDG_CONFIG_HOME/repoman/lrm/`. Lần chạy đầu sẽ
gieo mirror mặc định cho họ phân phối được nhận diện (Debian, RPM hoặc Arch).

Kiểm tra băng thông dùng [getbar](https://github.com/lenik/getbar) mặc định
`-c -d2 -p1 -w3 -s30m -i.1 -q`. Xem `lrm(1)` để biết chi tiết.

## Cấu trúc kho

- `lrm.in` — script chính (Meson tạo `build/lrm`)
- `lib/` — module backend (`common.sh`, `debian.sh`, `rpm.sh`, `arch.sh`, …)
- `po/` — danh mục gettext (`*.po` → `*.mo`)
- `man/<lang>/lrm.1.in` — trang manual từng ngôn ngữ (bảo trì thủ công)
- `README-<lang>.md` — README từng ngôn ngữ (bảo trì thủ công)
- `lrm.1.in` — nguồn manual tiếng Anh
- `debian/` — metadata đóng gói Debian
- `meson.build` — định nghĩa build cấp cao

## Nhật ký và màu

Khi stderr là TTY và có terminfo, dòng log được tô màu theo mức (`tput` trước, ANSI dự phòng):

| Mức | Cờ | Màu (thường) | Nội dung |
|-----|-----|--------------|----------|
| 0 | (mặc định) | xanh lá | tiến trình |
| 1 | `-v` | xanh lam | thử từng mirror |
| 2 | `-vv` | xanh dương | đường dẫn, sudo, distro |
| 3 | `-vvv` | tím | đo lường, lệnh |
| 4 | `-vvvv` | nhạt | đầu ra công cụ ngoài |
| warn | — | vàng | cảnh báo |
| err | — | đỏ đậm | lỗi |

Dùng `-q` để ẩn mọi thứ trừ lỗi.

## Quốc tế hóa

### Thông báo CLI (gettext)

Miền văn bản `lrm`. Thứ tự tìm danh mục: `po/` nguồn, `build/po/`, `$(localedir)`.

```bash
LANGUAGE=vi ./build/lrm -h
```

Meson biên dịch `po/*.po` thành `*.mo` khi build (giống getbar).

### Manual và README (dịch thủ công)

Nguồn tiếng Anh: `README.md`, `lrm.1.in`. Sửa trực tiếp `README-<lang>.md` và
`man/<lang>/lrm.1.in`. `<lang>` khớp `po/LINGUAS`. Xem `po/TRANSLATORS.md`.

## Build và cài đặt

```bash
sudo apt install meson ninja-build gettext
meson setup /build
ninja -C /build
meson install -C /build
```

Phụ thuộc runtime tùy chọn: **getbar**, **iputils-ping**.

## Gói Debian

```bash
dpkg-buildpackage -us -uc
```

## Giấy phép

Copyright (C) 2026 Lenik <repoman@bodz.net>

Theo **AGPL-3.0-or-later**.
