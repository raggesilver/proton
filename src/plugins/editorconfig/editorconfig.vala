/* editorconfig.vala
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

private class Editorconfig : Object, Proton.PluginIface {
    public void do_register(Proton.PluginLoader loader) {
        print("Editorconfig registered\n");

        loader.editor_changed.connect((ed) => {

            if (ed == null || ed.file == null)
                return ;

            var handler = new EditorConfig.Handle();
            if (handler.parse(ed.file.path) != 0) {
                print("Could not parse file %s\n", ed.file.name);
                return ;
            }

            int j = handler.get_name_value_count();
            for (int i = 0; i < j; i++) {
                string name, val;
                handler.get_name_value(i, out name, out val);

                switch (name) {
                    case "indent_style":
                        ed.sview.set_insert_spaces_instead_of_tabs(val == "space");
                        print("insert spaces [%s]\n", ed.sview.insert_spaces_instead_of_tabs ? "true" : "false");
                        break;

                    case "tab_width":
                        ed.sview.set_tab_width(int.parse(val));
                        break;

                    case "indent_size":
                        ed.sview.set_indent_width(int.parse(val));
                        break;

                    case "max_line_length":
                        ed.sview.right_margin_position = int.parse(val);
                        break;

                    default:
                        break;
                }
            }

        });
    }

    public void activate() {
        print("Activate\n");
    }

    public void deactivate() {
        print("Deactivate\n");
    }
}

public Type register_plugin (Module module) {
    return typeof(Editorconfig);
}
