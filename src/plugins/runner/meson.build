module_name = 'runner'

module_files = [
    'runner.vala',
]

module_deps = [
    proton_core_dep
]

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
