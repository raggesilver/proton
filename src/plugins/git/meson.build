module_name = 'git'

module_files = [
    'git.py',
]

custom_target(module_name,
    input: module_name + '.plugin',
    output: module_name + '.plugin',
    command : ['cp', '@INPUT@', '@OUTPUT@'],
    install: true,
    install_dir: join_paths(pluginsdir, module_name))

foreach f : module_files

    custom_target(f,
        input: f,
        output: f,
        command : ['cp', '@INPUT@', '@OUTPUT@'],
        install: true,
        install_dir: join_paths(pluginsdir, module_name))

endforeach
