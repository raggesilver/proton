proton_sources = [
  'main.vala',
]

subdir('widgets')
subdir('extra')
subdir('utils')

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))

config_header = configure_file(
                input: 'config.vala.in',
               output: 'config.vala',
        configuration: conf_data
        )

proton_sources += config_header

proton_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  dependency('marble', version: '>= 1.2.2'),
  dependency('gee-0.8', version: '>= 0.8.0'),
]

gnome = import('gnome')

proton_sources += gnome.compile_resources('proton-resources',
  'proton.gresource.xml',
  c_name: 'proton'
)

executable('proton', proton_sources,
  vala_args: '--target-glib=2.50',  dependencies: proton_deps,
  install: true,
  c_args: '-DHANDY_USE_UNSTABLE_API=1'
)
