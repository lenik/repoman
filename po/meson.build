i18n = import('i18n')

i18n.gettext(
    'lrm',
    data_dirs: meson.project_source_root(),
    args: [
        '--from-code=UTF-8',
        '--language=Shell',
        '--add-comments=TRANSLATORS:',
        '--keyword=_',
        '--keyword=ngettext:1,2',
        '--keyword=die:1c-format',
        '--keyword=warn:1c-format',
    ],
    install: true,
)
