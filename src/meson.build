proton_sources = [
  'main.vala',
  'window.vala',
  'application.vala',
  'open_window.vala',
  'utils/File.vala',
  'services/Settings.vala',
  #'services/PluginManager.vala',
  'services/Core.vala',
  'services/EditorManager.vala',
  'widgets/TreeView.vala',
  'widgets/Editor.vala',
  'widgets/Container.vala',
  'widgets/Terminal.vala',
  'widgets/LinkedToggler.vala',
]

proton_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gmodule-2.0', version: '>= 2.50'),
  dependency('vte-2.91', version: '>= 0.54.1'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('gtksourceview-3.0', version: '>= 3.22'),
  dependency('granite') # this ain't no elementary app ok babydora?
]

gnome = import('gnome')

proton_sources += gnome.compile_resources('proton-resources',
  'proton.gresource.xml',
  c_name: 'proton'
)

executable('proton', proton_sources,
  vala_args: '--target-glib=2.50',  dependencies: proton_deps,
  install: true,
)
