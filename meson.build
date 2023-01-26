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

add_project_arguments(vala_flags, language: 'vala')

subdir('data')
subdir('src')
subdir('po')
