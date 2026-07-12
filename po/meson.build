i18n = import('i18n')

i18n.gettext(
    'lrm',
    args: [
        '--from-code=UTF-8',
        '--language=Shell',
        '--add-comments=TRANSLATORS:',
        '--keyword=_',
        '--keyword=ngettext:1,2',
        '--keyword=die:1c-format',
        '--keyword=warn:1c-format',
    ],
    preset: 'glib',
    install: true,
    install_dir: get_option('localedir'),
)

run_target(
    'posync',
    command: [
        'bash',
        meson.project_source_root() / 'po' / 'posync.sh',
        meson.project_source_root(),
        meson.project_build_root(),
    ],
)
