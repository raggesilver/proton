/* preferences_window.vala
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

class Row : Gtk.ListBoxRow
{
    public string page_name;

    public Row(string s)
    {
        var lbl = new Gtk.Label(s);
        lbl.margin = 5;
        lbl.margin_start = lbl.margin_end = 10;
        lbl.xalign = 0;

        page_name = s.down();

        add(lbl);
        show_all();
    }
}

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/preferences_window.ui")]
public class Proton.PreferencesWindow : Gtk.ApplicationWindow
{
    [GtkChild]
    Gtk.Box layout_box;

    [GtkChild]
    Gtk.ListBox side_list_box;

    [GtkChild]
    Gtk.Stack stack;

    public Array<string> menus { get; private set; }

    public PreferencesWindow(Window _win)
    {
        Object(application: _win.application);
        set_transient_for(_win);

        string[] ss = { "Appearence", "Editor" };

        foreach (string s in ss)
        {
            var l = new Row(s);
            side_list_box.insert(l, -1);
        }

        side_list_box.row_activated.connect((_r) => {
            var r = _r as Row;
            stack.set_visible_child_name(r.page_name);
        });

        var c = new Gtk.SourceStyleSchemeChooserWidget();
        c.set_style_scheme(Gtk.SourceStyleSchemeManager.get_default()
            .get_scheme(settings.style_id));

        c.notify["style-scheme"].connect(() => {
            settings.style_id = c.style_scheme.id;
        });

        layout_box.pack_start(c, false, true, 0);
        c.show();
    }
}
