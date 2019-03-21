module_name = 'editorconfig'

module_files = [
    'editorconfig.vala',
    'editorconfig.vapi',
]

module_deps = [
    proton_core_dep,
    meson.get_compiler('c').find_library('editorconfig'),
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
