# warning_level unused; 'c' language required by Meson < 0.45 for project().
project(
    'repoman',
    'c',
    version: run_command(
        'sh',
        '-c', '''
        v=$(git describe --tags --always --dirty 2>/dev/null || true)
        v=${v#v}
        if [ -n "$v" ]; then
            if [ "${v%.*}" = "$v" ]; then
                v="0.0.0-$v"
            fi
            printf "%s" "$v"
        else
            echo "0.0.0"
        fi
        ''',
        # omit check: for Meson < 0.47
    ).stdout().strip(),
    license: 'AGPL-3.0-or-later',
)

project_author = 'Lenik'
project_email = 'repoman@bodz.net'
project_year = 2026

meson_has_path_op = meson.version().version_compare('>=0.49.0')
meson_has_fs = meson.version().version_compare('>=0.53.0')
meson_has_project_source_root = meson.version().version_compare('>=0.56.0')
meson_has_strip_dir = meson.version().version_compare('>=0.45.0')
meson_has_install_mode = meson.version().version_compare('>=0.38.0')

if meson_has_fs
    fs = import('fs')
endif

if meson_has_path_op
    prefix = get_option('prefix')
    bindir = prefix / get_option('bindir')
    datadir = prefix / get_option('datadir')
    localedir = prefix / get_option('localedir')
    mandir = prefix / get_option('mandir')
    pkgdatadir = datadir / meson.project_name()
    pkgdocdir = datadir / 'doc' / meson.project_name()
else
    prefix = get_option('prefix')
    bindir = join_paths(prefix, get_option('bindir'))
    datadir = join_paths(prefix, get_option('datadir'))
    localedir = join_paths(prefix, get_option('localedir'))
    mandir = join_paths(prefix, get_option('mandir'))
    pkgdatadir = join_paths(datadir, meson.project_name())
    pkgdocdir = join_paths(datadir, 'doc', meson.project_name())
endif

if meson_has_project_source_root
    src_root = meson.project_source_root()
    build_root = meson.project_build_root()
else
    src_root = meson.source_root()
    build_root = meson.build_root()
endif

project_config = configuration_data()
project_config.set('PROJECT_VERSION', meson.project_version())
project_config.set('PROJECT_AUTHOR', project_author)
project_config.set('PROJECT_EMAIL', project_email)
project_config.set('PROJECT_YEAR', project_year)
project_config.set('LRM_TEXTDOMAIN', 'lrm')
project_config.set('LRM_SOURCE_LOCALEDIR', join_paths(src_root, 'po'))
project_config.set('LRM_BUILD_LOCALEDIR', join_paths(build_root, 'po'))
project_config.set('LRM_INSTALL_LOCALEDIR', localedir)
project_config.set('DRM_TEXTDOMAIN', 'drm')
project_config.set('DRM_SOURCE_LOCALEDIR', join_paths(src_root, 'po'))
project_config.set('DRM_BUILD_LOCALEDIR', join_paths(build_root, 'po'))
project_config.set('DRM_INSTALL_LOCALEDIR', localedir)

if meson_has_install_mode
    lrm_script = configure_file(
        input: 'lrm.in',
        output: 'lrm',
        configuration: project_config,
        install: true,
        install_dir: bindir,
        install_mode: 'rwxr-xr-x',
    )
    drm_script = configure_file(
        input: 'drm.in',
        output: 'drm',
        configuration: project_config,
        install: true,
        install_dir: bindir,
        install_mode: 'rwxr-xr-x',
    )
else
    lrm_script = configure_file(
        input: 'lrm.in',
        output: 'lrm',
        configuration: project_config,
        install: true,
        install_dir: bindir,
    )
    drm_script = configure_file(
        input: 'drm.in',
        output: 'drm',
        configuration: project_config,
        install: true,
        install_dir: bindir,
    )
endif

# Dev convenience: build/{lrm,drm} expect SCRIPT_DIR/share/...
run_command(
    'ln',
    '-sfn',
    join_paths(meson.current_source_dir(), 'share'),
    join_paths(meson.current_build_dir(), 'share'),
)

if meson_has_strip_dir
    install_subdir(
        'share',
        install_dir: pkgdatadir,
        strip_directory: true,
    )
else
    # Meson < 0.45: install share/* directly under pkgdatadir via script.
    # Bake source dir into the script (MESON_SOURCE_ROOT is not reliable on 0.37).
    meson.add_install_script(
        'sh', '-c',
        'd="${DESTDIR}' + pkgdatadir + '"; mkdir -p "$d"; cp -a "' + join_paths(meson.current_source_dir(), 'share') + '/." "$d/"; chmod -R a+rX "$d"; chmod a+x "${DESTDIR}' + bindir + '/lrm" "${DESTDIR}' + bindir + '/drm"',
    )
endif

bash_files = [
    'lrm.bash',
    'drm.bash',
]

bash_completions_dir = join_paths(datadir, 'bash-completion', 'completions')
foreach file : bash_files
    if meson_has_fs
        name = fs.stem(file)
    else
        name = file.split('.')[0]
    endif
    install_data(
        file,
        install_dir: bash_completions_dir,
        rename: name,
    )
endforeach

install_data(
    'LICENSE',
    install_dir: pkgdocdir,
)

readme_langs = ['zh_CN', 'zh_TW', 'ja', 'ko', 'th', 'vi', 'fr', 'de', 'it', 'eo']
doc_install = ['README.md']
foreach lang : readme_langs
    doc_install += ['README-' + lang + '.md']
endforeach

install_data(
    doc_install,
    install_dir: pkgdocdir,
)

# Backward-compatible alias for Chinese readme.
install_data(
    'README-zh_CN.md',
    install_dir: pkgdocdir,
    rename: 'README-zh.md',
)

manpage_langs = ['de', 'eo', 'fr', 'it', 'ja', 'ko', 'th', 'vi', 'zh_CN', 'zh_TW']
foreach lang : manpage_langs
    manin = join_paths('man', lang, 'lrm.1.in')
    manin_abs = join_paths(meson.current_source_dir(), manin)
    manin_exists = false
    if meson_has_fs and meson_has_path_op
        manin_exists = fs.is_file(meson.current_source_dir() / manin)
    else
        probe = run_command(
            'sh', '-c', 'test -f "$1" && echo yes || echo no',
            'sh',
            manin_abs,
        )
        manin_exists = probe.stdout().strip() == 'yes'
    endif
    if manin_exists
        man_out = configure_file(
            input: manin,
            output: 'lrm.1-' + lang,
            configuration: project_config,
        )
        install_data(
            man_out,
            install_dir: join_paths(mandir, lang, 'man1'),
            rename: 'lrm.1',
        )
    endif
endforeach

configure_file(
    input: 'lrm.1.in',
    output: 'lrm.1',
    configuration: project_config,
    install: true,
    install_dir: join_paths(mandir, 'man1'),
)

configure_file(
    input: 'drm.1.in',
    output: 'drm.1',
    configuration: project_config,
    install: true,
    install_dir: join_paths(mandir, 'man1'),
)

if meson_has_project_source_root
    subdir('po')
endif

# look / install-symlinks / uninstall-symlinks omitted: multiline `bash -euc`
# scripts put newlines into ninja rules (broken on Meson 0.37; hard error ≥0.56).
