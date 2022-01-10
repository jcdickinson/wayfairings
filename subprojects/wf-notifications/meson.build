# project name and programming language
project('wf-notifications', 'vala', 'c')
add_project_arguments('--debug', language: 'vala')

gnome = import('gnome')
i18n = import('i18n')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    dependency('gee-0.8'),
    dependency('polkit-agent-1'),
    dependency('polkit-gobject-1'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('gtk-layer-shell')
]

sources = files(
    'src/Application.vala',
    'src/AbstractToast.vala',
    'src/NotificationToast.vala',
    'src/NotificationServer.vala',
    'src/Notification.vala',
    'src/CloseReason.vala',
    'src/ToastStack.vala',
    'src/ToastAxis.vala',
    'src/PolkitServer.vala',
    'src/Authn.vala',
    'src/AuthnToast.vala'
)

sources += gnome.compile_resources(
    'gresource',
    'data/gresource.xml',
    source_dir: 'data'
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    sources,
    vala_args: ['--pkg=GtkLayerShell-0.1'],
    dependencies: dependencies,
    c_args: [
        '-DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE',
    ],
    install: true
)

# Install our .desktop file so the Applications ls /usr/share/vala-0.48/vapi/ | grep -P \^\(gtk\|glib\|gobject\|posix\)Menu will see it
# install_data(
#     'data' / 'hello-again.desktop',
#     install_dir: get_option('datadir') / 'applications',
#     rename: meson.project_name() + '.desktop'
# )

# Install our .metainfo.xml file so AppCenter will see it
# install_data(
#     'data' / 'hello-again.metainfo.xml',
#     install_dir: get_option('datadir') / 'metainfo',
#     rename: meson.project_name() + '.metainfo.xml'
# )