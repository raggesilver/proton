module_name = 'runner'

module_files = [
    'runner.vala',
    'runner_setup.vala'
]

module_deps = [
    proton_core_dep
]

gnome = import('gnome')

module_files += gnome.compile_resources('runner-resources',
  'runner.gresource.xml',
  c_name: 'runner'
)

shared_module(
    module_name,
    module_files,
    dependencies: module_deps,
    install: true,
    install_dir: join_paths(pluginsdir, module_name),
)

custom_target(module_name,
    input: module_name + '.plugin',
    output: module_name + '.plugin',
    command : ['cp', '@INPUT@', '@OUTPUT@'],
    install: true,
    install_dir: join_paths(pluginsdir, module_name))
