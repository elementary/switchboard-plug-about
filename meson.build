project(
    'about',
    'vala', 'c',
    version: '2.5.2'
)

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

if get_option('with-update-button')
    add_project_arguments('--define=HAS_UPDATE_BUTTON', language: 'vala')
endif

subdir('data')
subdir('src')
subdir('po')
