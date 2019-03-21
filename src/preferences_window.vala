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
public class Proton.PreferencesWindow : Gtk.ApplicationWindow {

    [GtkChild]
    Gtk.Box layout_box;

    public PreferencesWindow(Gtk.Application app) {
        Object(application: app);

        var c = new Gtk.SourceStyleSchemeChooserWidget();
        c.set_style_scheme(Gtk.SourceStyleSchemeManager.get_default()
            .get_scheme(settings.style_id));

        c.notify.connect((p) => {
            if (p.get_name() == "style-scheme") {
                settings.style_id = c.style_scheme.id;
            }
        });

        layout_box.pack_start(c, false, true, 0);
        c.show();
    }
}
