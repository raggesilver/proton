
pluginsdir = join_paths(get_option('prefix'), get_option('libdir'), 'proton/plugins')

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('PLUGINDIR', pluginsdir)
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

proton_sources = [
  'main.vala',
  'window.vala',
  'application.vala',
  'open_window.vala',
  'preferences_window.vala',
  'utils/File.vala',
  'utils/utils.vala',
  'utils/threading.vala',
  'services/Settings.vala',
  'services/PluginManager.vala',
  'services/Core.vala',
  'services/EditorManager.vala',
  'widgets/TreeView.vala',
  'widgets/Editor.vala',
  'widgets/Container.vala',
  'widgets/Terminal.vala',
  'widgets/CommandPalette.vala',
]

proton_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gmodule-2.0', version: '>= 2.50'),
  dependency('vte-2.91', version: '>= 0.54.1'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('gtksourceview-3.0', version: '>= 3.22'),
  dependency('granite'), # this ain't no elementary app ok babydora?
  meson.get_compiler('vala').find_library('posix'),
  meson.get_compiler('vala').find_library('linux'),
]

gnome = import('gnome')

proton_sources += gnome.compile_resources('proton-resources',
  'proton.gresource.xml',
  c_name: 'proton'
)

executable('proton', proton_sources, config_header,
  vala_args: '--target-glib=2.50',  dependencies: proton_deps,
  install: true,
)

proton_core = library(
    'proton_core',
    proton_sources,
    config_header,
    dependencies: proton_deps,
    install: true,
    install_dir: [true, true, true],
    version: '0.0'
)

pkg = import('pkgconfig')

pkg.generate(
    version: '0.1',
    libraries: proton_core,
    description: 'Proton core',
    name: 'proton_core',
    filebase: 'proton_core'
)

install_data('proton_core.deps',
             install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'vala', 'vapi'))

proton_core_dep = declare_dependency(
    link_with: proton_core,
    dependencies: proton_deps,
    include_directories: [include_directories('.')])

subdir('plugins')

