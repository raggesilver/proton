/* GlobalSearch.vala
 *
 * Copyright 2020 Paulo Queiroz <pvaqueiroz@gmail.com>
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

public class Proton.GlobalSearchSettings : Marble.Settings
{
    private static Proton.GlobalSearchSettings? instance = null;

    public bool auto_save_modified { get; set; }

    private GlobalSearchSettings()
    {
        base("com.raggesilver.Proton.global-search");
    }

    public static Proton.GlobalSearchSettings get_instance()
    {
        if (instance == null)
            instance = new Proton.GlobalSearchSettings();
        return (instance);
    }
}

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/global_search.ui")]
public class Proton.GlobalSearch : Gtk.Box
{
    [GtkChild] private Gtk.Revealer include_files_revealer;
    [GtkChild] private Gtk.Revealer replace_revealer;
    [GtkChild] private Gtk.ToggleButton include_files_toggle_button;
    [GtkChild] private Gtk.Image toggle_image;
    [GtkChild] private Gtk.CheckButton auto_save_modified_check;
    [GtkChild] private Gtk.Entry search_entry;
    [GtkChild] private Gtk.Entry replace_entry;

    private weak Window window;
    private GlobalSearchSettings gs_settings;

    public GlobalSearch(Window window)
    {
        this.window = window;
        this.gs_settings = GlobalSearchSettings.get_instance();

        this.auto_save_modified_check.active = this.gs_settings
                                                   .auto_save_modified;
        this.gs_settings.schema.bind("auto-save-modified",
                                     this.auto_save_modified_check, "active",
                                     SettingsBindFlags.DEFAULT);

        // Bind accels
        this.bind_accels();
    }

    private void bind_accels()
    {
        this.window.key_press_event.connect((e) => {
            if ((e.state & Gdk.ModifierType.CONTROL_MASK) == 0 ||
                (e.state & Gdk.ModifierType.SHIFT_MASK) == 0)
                return (false);
            switch (Gdk.keyval_name(e.keyval))
            {
                case "F": { this.on_ctrl_shift_f(); return (true); }
                case "H": { this.on_ctrl_shift_h(); return (true); }
                default: return (false);
            }
        });
    }

    private void on_ctrl_shift_f()
    {
        this.window.side_panel_stack.set_visible_child_name("globalsearch");
        this.search_entry.grab_focus();
    }

    private void on_ctrl_shift_h()
    {
        this.window.side_panel_stack.set_visible_child_name("globalsearch");

        if (!this.replace_revealer.reveal_child)
            this.on_toggle_replace();

        this.replace_entry.grab_focus();
    }

    [GtkCallback]
    private void on_include_files_toggled()
    {
        this.include_files_revealer.reveal_child =
            this.include_files_toggle_button.active;
    }

    [GtkCallback]
    private void on_toggle_replace()
    {
        this.replace_revealer.reveal_child =
            !this.replace_revealer.reveal_child;

        this.toggle_image.set_from_icon_name(
            (this.replace_revealer.reveal_child) ? "go-down-symbolic" :
            "go-next-symbolic", Gtk.IconSize.MENU
        );
    }
}
