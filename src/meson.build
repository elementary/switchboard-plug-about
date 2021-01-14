plug_files = files(
    'fd.c',
    'Plug.vala',
    'Objects/Details.vala',
    'Objects/Device.vala',
    'Objects/DeviceFlag.vala',
    'Objects/Release.vala',
    'Objects/ReleaseFlag.vala',
    'Interfaces/FwupdManager.vala',
    'Utils/ARMPartDecoder.vala',
    'Views/FirmwareView.vala',
    'Views/HardwareView.vala',
    'Views/OperatingSystemView.vala',
    'Widgets/FirmwareUpdateWidget.vala'
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

shared_module(
    meson.project_name(),
    plug_files,
    css_gresource,
    dependencies: [
        dependency('glib-2.0', version: '>=2.64.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libgtop-2.0'),
        dependency('libhandy-1'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'hardware')
)
