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
        var buff = ed.sview.buffer;
        var vadjust = (ed.sview.parent as Gtk.ScrolledWindow).get_vadjustment();

        Gtk.TextIter it;
        buff.get_iter_at_offset(out it, buff.cursor_position);

        int line = it.get_line();
        int offset = it.get_line_offset();
        double scroll_position = vadjust.value;

        Gtk.TextIter lit, lit_end;
        int lines = ed.sview.buffer.get_line_count();
        int chars = 0;
        int to_remove;
        string line_text = "";

        buff.begin_user_action();

        for (int i = 0; i < lines; i++)
        {
            to_remove = 0;
            ed.sview.buffer.get_iter_at_line(out lit, i);
            chars = lit.get_chars_in_line();
            ed.sview.buffer.get_iter_at_line_offset(out lit_end, i, chars);

            line_text = ed.sview.buffer.get_text(lit, lit_end, true);
            to_remove = line_text.length;

            line_text._chomp();
            to_remove -= line_text.length;

            if (to_remove > 0)
            {
                lit.assign(lit_end);
                lit.backward_chars(to_remove);
                ed.sview.buffer.delete(ref lit, ref lit_end);
            }
        }

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
