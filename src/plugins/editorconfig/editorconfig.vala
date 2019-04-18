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

private class Editorconfig : Object, Proton.PluginIface
{
    public void do_register(Proton.PluginLoader loader)
    {
        loader.window.manager.created.connect((ed) => {

            if (ed == null || ed.file == null)
                return ;

            var handler = new EditorConfig.Handle();
            if (handler.parse(ed.file.path) != 0)
            {
                warning("Could not parse file %s\n", ed.file.name);
                return ;
            }

            int j = handler.get_name_value_count();
            for (int i = 0; i < j; i++)
            {
                string name, val;
                handler.get_name_value(i, out name, out val);

                switch (name)
                {
                    case "indent_style":
                        ed.sview.set_insert_spaces_instead_of_tabs(
                            val == "space");
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

                    case "trim_trailing_whitespace":
                        ed.before_save.connect(() => {
                            return (on_before_save(ed));
                        });
                        break;

                    default:
                        break;
                }
            }

        });
    }

    bool on_before_save(Proton.Editor ed)
    {
        Gtk.TextIter it;

        var buff = ed.sview.buffer;

        buff.get_iter_at_offset(out it, buff.cursor_position);

        int line = it.get_line();
        int offset = it.get_line_offset();

        buff.begin_user_action();

        string[] arr = ed.get_text().split("\n");
        string new_text = arr[0]._chomp();

        for (ulong k = 1; k < arr.length; k++)
            new_text += ("\n" + arr[k]._chomp());

        buff.set_text(new_text);

        // Restore cursor location
        buff.get_iter_at_line(out it, line);

        int in_line = it.get_chars_in_line();
        if (in_line < offset) // If current cursor line was modified
            offset = in_line - 1;

        it.set_line(line);
        it.set_line_offset(offset);
        buff.place_cursor(it);

        buff.end_user_action();

        return (false);
    }

    public void activate()
    {
    }

    public void deactivate()
    {
    }
}

public Type register_plugin (Module module)
{
    return typeof(Editorconfig);
}
