# Translators' notes

## CLI strings (gettext)

- Template: `po/lrm.pot` (sources listed in `po/POTFILES`)
- Catalogs: `po/<lang>.po` for each entry in `po/LINGUAS`
- Edit `.po` files by hand or with poedit

Meson `i18n.gettext()` in `po/meson.build` compiles catalogs at build time
(like getbar). When translatable strings change, refresh `po/lrm.pot` and merge
into `po/*.po` with the usual gettext tools (`xgettext`, `msgmerge`).

## Manual pages and READMEs

- English sources: `lrm.1.in`, `README.md`
- Per language (manual only):
  - `man/<lang>/lrm.1.in` → installed as `man/<lang>/man1/lrm.1`
  - `README-<lang>.md` → installed under `share/doc/repoman/`

When `lrm.1.in` or `README.md` changes, update each translation file directly.
There is no documentation generator in this project.

Checked-in translations (one row per `po/LINGUAS` entry):

| lang   | man                    | README            |
|--------|------------------------|-------------------|
| de     | man/de/lrm.1.in        | README-de.md      |
| eo     | man/eo/lrm.1.in        | README-eo.md      |
| fr     | man/fr/lrm.1.in        | README-fr.md      |
| it     | man/it/lrm.1.in        | README-it.md      |
| ja     | man/ja/lrm.1.in        | README-ja.md      |
| ko     | man/ko/lrm.1.in        | README-ko.md      |
| th     | man/th/lrm.1.in        | README-th.md      |
| vi     | man/vi/lrm.1.in        | README-vi.md      |
| zh_CN  | man/zh_CN/lrm.1.in     | README-zh_CN.md   |
| zh_TW  | man/zh_TW/lrm.1.in     | README-zh_TW.md   |

`README-zh_CN.md` is also installed as `README-zh.md` for backward compatibility.
