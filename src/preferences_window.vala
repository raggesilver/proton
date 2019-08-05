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

internal class PluginRow : Gtk.Box
{
    public Gtk.Switch sw { get; private set; }
    public Gtk.Label lbl { get; private set; }
    public Gtk.Image img { get; private set; }

    internal PluginRow(string name, bool enabled)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 12);

        this.lbl = new Gtk.Label(name);
        this.lbl.xalign = 0;
        this.lbl.margin_start = 12;

        this.pack_start(this.lbl, true, true, 0);

        this.img = new Gtk.Image.from_icon_name("go-next-symbolic",
                                               Gtk.IconSize.MENU);
        this.img.margin_end = 12;

        this.pack_end(this.img, false, true, 0);

        this.sw = new Gtk.Switch();
        this.sw.active = enabled;
        this.sw.valign = Gtk.Align.CENTER;

        this.pack_end(this.sw, false, true, 0);

        this.set_size_request(-1, 50);
        this.show_all();
    }
}

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/preferences_window.ui")]
public class Proton.PreferencesWindow : Gtk.ApplicationWindow
{
    [GtkChild]
    Gtk.Box color_scheme_box;

    [GtkChild]
    Gtk.FontButton font_button;

    [GtkChild]
    Gtk.Stack plugin_stack;

    [GtkChild]
    Gtk.ListBox plugin_list_box;

    private weak Window window;

    public PreferencesWindow(Window window)
    {
        Object(application: window.application);

        this.window = window;

        var c = new Gtk.SourceStyleSchemeChooserButton();
        c.set_style_scheme(Gtk.SourceStyleSchemeManager.get_default()
            .get_scheme(EditorSettings.get_instance().style_id));

        c.notify["style-scheme"].connect(() => {
            EditorSettings.get_instance().style_id = c.style_scheme.id;
        });

        color_scheme_box.add(c);
        color_scheme_box.show_all();

        font_button.font = EditorSettings.get_instance().font_family;

        foreach (var plug in window.pm.get_plugins())
        {
            var row = new PluginRow(plug.iface.name, plug.iface.active);

            plug.iface.notify["active"].connect(() => {
                row.sw.active = plug.iface.active;
            });

            plugin_list_box.insert(row, -1);
        }
    }

    [GtkCallback]
    void on_font_set()
    {
        debug("Font set '%s'", font_button.font);
        EditorSettings.get_instance().font_family = font_button.font;
    }

    [GtkCallback]
    void on_back_to_plugin_list()
    {
        this.plugin_stack.set_visible_child_name("plugin_list");
    }
}
