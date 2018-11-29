
conf_data = configuration_data()
conf_data.set('DISTRO_ICON_NAME', get_option('distributor-icon-name'))

config_header = configure_file (
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: conf_data
)

plug_files = files(
    'Plug.vala',
    'Dialogs/IssueDialog.vala',
    'Dialogs/RestoreDialog.vala',
    'Views/HardwareView.vala'
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    config_header,
    plug_files,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'hardware')
)
