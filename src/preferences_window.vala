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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/preferences_window.ui")]
public class Proton.PreferencesWindow : Gtk.ApplicationWindow
{
    [GtkChild] Gtk.Box color_scheme_box;
    [GtkChild] Gtk.FontButton font_button;
    [GtkChild] Gtk.Switch dark_mode_switch;
    [GtkChild] Gtk.Switch transparency_switch;
    [GtkChild] Gtk.Switch word_wrap_switch;

    private weak Window     window;
    private Settings        settings;
    private EditorSettings  ed_settings;

    public PreferencesWindow(Window _win)
    {
        Object(application: _win.application);

        this.window = _win;
        this.settings = Settings.get_instance();
        this.ed_settings = EditorSettings.get_instance();

        this.set_transient_for(_win);

        var c = new Gtk.SourceStyleSchemeChooserButton();
        c.set_style_scheme(Gtk.SourceStyleSchemeManager.get_default()
            .get_scheme(this.ed_settings.style_id));

        c.notify["style-scheme"].connect(() => {
            this.ed_settings.style_id = c.style_scheme.id;
        });

        color_scheme_box.add(c);
        color_scheme_box.show_all();

        font_button.font = this.ed_settings.font_family;

        this.settings.schema.bind("dark-mode", this.dark_mode_switch,
                                  "active", SettingsBindFlags.DEFAULT);
        this.dark_mode_switch.active = this.settings.dark_mode;

        this.settings.schema.bind("transparency", this.transparency_switch,
                                  "active", SettingsBindFlags.DEFAULT);
        this.transparency_switch.active = this.settings.transparency;

        this.ed_settings.schema.bind("word-wrap", this.word_wrap_switch,
                                     "active", SettingsBindFlags.DEFAULT);
        this.word_wrap_switch.active = this.ed_settings.word_wrap;
    }

    [GtkCallback]
    void on_font_set()
    {
        debug("Font set '%s'", font_button.font);
        EditorSettings.get_instance().font_family = font_button.font;
    }
}
