i18n.merge_file(
    input: 'system.metainfo.xml.in',
    output: 'io.elementary.settings.system.metainfo.xml.in',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(datadir, 'metainfo'),
    install: true
)

css_gresource = gnome.compile_resources(
    'gresource_css',
    'gresource.xml'
)
