i18n.merge_file(
    input: 'io.elementary.switchboard.about.appdata.xml.in',
    output: 'io.elementary.switchboard.about.appdata.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(datadir, 'metainfo'),
    install: true
)

css_gresource = gnome.compile_resources(
    'gresource_css',
    'gresource.xml'
)
