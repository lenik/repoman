project(
    'repoman',
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
        check: false,
    ).stdout().strip(),
    license: 'AGPL-3.0-or-later',
)

project_author = 'Lenik'
project_email = 'repoman@bodz.net'
project_year = 2026

fs = import('fs')

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
localedir = prefix / get_option('localedir')
mandir = prefix / get_option('mandir')
pkgdatadir = datadir / meson.project_name()
pkgdocdir = datadir / 'doc' / meson.project_name()

project_config = configuration_data()
project_config.set('PROJECT_VERSION', meson.project_version())
project_config.set('PROJECT_AUTHOR', project_author)
project_config.set('PROJECT_EMAIL', project_email)
project_config.set('PROJECT_YEAR', project_year)
project_config.set('LRM_TEXTDOMAIN', 'lrm')
project_config.set('LRM_SOURCE_LOCALEDIR', meson.project_source_root() / 'po')
project_config.set('LRM_BUILD_LOCALEDIR', meson.project_build_root() / 'po')
project_config.set('LRM_INSTALL_LOCALEDIR', localedir)

lrm_script = configure_file(
    input: 'lrm.in',
    output: 'lrm',
    configuration: project_config,
    install: true,
    install_dir: bindir,
    install_mode: 'rwxr-xr-x',
)

# Dev convenience: build/lrm expects SCRIPT_DIR/lib (see lrm.in).
run_command(
    'ln',
    '-sfn',
    meson.current_source_dir() / 'lib',
    meson.current_build_dir() / 'lib',
    check: false,
)

install_subdir(
    'lib',
    install_dir: pkgdatadir / 'lrm',
)

bash_files = [
    'lrm.bash',
]

foreach file : bash_files
    name = fs.stem(file)
    install_data(
        file,
        install_dir: datadir / 'bash-completion' / 'completions',
        rename: name,
    )
endforeach

install_data(
    'LICENSE',
    install_dir: pkgdocdir,
)

install_data(
    'README.md',
    install_dir: pkgdocdir,
)

# Backward-compatible alias for Chinese readme.
install_data(
    'doc/README-zh_CN.md',
    install_dir: pkgdocdir,
    rename: 'README-zh.md',
)

doc_langs = ['zh_CN', 'zh_TW', 'ja', 'ko', 'th', 'vi', 'fr', 'de', 'it', 'eo']
foreach lang : doc_langs
    readme_src = 'doc/README-' + lang + '.md'
    if fs.exists(readme_src)
        install_data(
            readme_src,
            install_dir: pkgdocdir,
        )
    endif
    man_src = 'po/lrm.1-' + lang + '.in'
    if fs.exists(man_src)
        man_out = configure_file(
            input: man_src,
            output: 'lrm.1-' + lang,
            configuration: project_config,
        )
        install_data(
            man_out,
            install_dir: mandir / lang / 'man1',
            rename: 'lrm.1',
        )
    endif
endforeach

configure_file(
    input: 'lrm.1.in',
    output: 'lrm.1',
    configuration: project_config,
    install: true,
    install_dir: mandir / 'man1',
)

subdir('po')

# look task: list what installed files looks like
# ninja install <tmpdir> && tree <tmpdir> && rm -fr <tmpdir>
run_target(
    'look',
    command: [
        'bash',
        '-euc', '''
            tmpdir=$(mktemp -d)
            DESTDIR=$tmpdir meson install -C "@BUILD_ROOT@"
            tree "$tmpdir"
            rm -fr "$tmpdir"
        ''',
    ],
)

# Fast local debugging against the active installation prefix:
# symlink installed paths to project/build outputs.
run_target(
    'install-symlinks',
    command: [
        'bash',
        '-euc', '''
            prefix="@0@"
            bindir="@1@"
            datadir="@2@"
            localedir="@3@"
            mandir="@4@"

            pkgdatadir="@5@"

            mkdir -p "$bindir" "$datadir/bash-completion/completions" "$localedir" "$mandir/man1" "$pkgdatadir"

            sudo ln -sfn "@BUILD_ROOT@/lrm" "$bindir/lrm"
            sudo ln -sfn "@BUILD_ROOT@/lrm.1" "$mandir/man1/lrm.1"
            sudo ln -sfn "@SOURCE_ROOT@/lrm.bash" "$datadir/bash-completion/completions/lrm"
            sudo ln -sfn "@SOURCE_ROOT@/lib" "$pkgdatadir/lib"

            printf "Symlinks installed under %s\n" "$prefix"
        '''.format(
            get_option('prefix'), #
            bindir,
            datadir,
            localedir,
            mandir,
            pkgdatadir / 'lrm',
        ),
    ],
)

run_target(
    'uninstall-symlinks',
    command: [
        'bash',
        '-euc', '''
            prefix="@0@"
            bindir="@1@"
            datadir="@2@"
            localedir="@3@"
            mandir="@4@"

            pkgdatadir="@5@"

            for p in \
                "$bindir/lrm" \
                "$mandir/man1/lrm.1" \
                "$datadir/bash-completion/completions/lrm" \
                "$pkgdatadir/lib"
            do
                if [ -L "$p" ]; then
                    sudo rm -f "$p"
                    printf "Removed %s\n" "$p"
                else
                    printf "Skipped (not a symlink): %s\n" "$p"
                fi
            done
        '''.format(
            get_option('prefix'), #
            bindir,
            datadir,
            localedir,
            mandir,
            pkgdatadir / 'lrm',
        ),
    ],
)
