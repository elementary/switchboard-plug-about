project(
    'about',
    'vala', 'c',
    version: '6.2.0'
)

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

glib_dep = dependency('glib-2.0', version: '>=2.64.0')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

vapi_dir = join_paths(meson.current_source_dir(), 'vapi')
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

vala_flags = []

if get_option('wallpaper')
    vala_flags += ['--define', 'WALLPAPER']
endif

if glib_dep.version().version_compare ('>=2.73.0')
    vala_flags += ['--define', 'HAS_GLIB_2_73']
endif

add_project_arguments(vala_flags, language: 'vala')

subdir('data')
subdir('src')
subdir('po')
