# Translators' notes

## CLI strings (gettext)

- Template: `po/lrm.pot` (from `xgettext` via `ninja -C build posync`)
- Catalogs: `po/<lang>.po` for each entry in `po/LINGUAS`
- Edit `.po` files by hand or with poedit; never auto-generate prose

## Manual pages and READMEs

- English sources: `lrm.1.in`, `README.md`
- Per language (manual only):
  - `po/lrm.1-<lang>.in` → installed as `man/<lang>/man1/lrm.1`
  - `doc/README-<lang>.md` → installed under `share/doc/repoman/`

When `lrm.1.in` or `README.md` changes, update each translation file directly.
There is no documentation generator in this project.

Currently checked in:

| lang   | man              | README              |
|--------|------------------|---------------------|
| zh_CN  | lrm.1-zh_CN.in   | doc/README-zh_CN.md |

Add rows as new manual translations land.
