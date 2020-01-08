/* EditorSearchBox.vala
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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/editor_search_box.ui")]
public class Proton.EditorSearchBox : Gtk.Box
{
    weak Gtk.SourceView   view;
    weak Gtk.SourceBuffer buff;

    [GtkChild] Gtk.Revealer advanced_revealer;
    [GtkChild] Gtk.Button advanced_toggle_button;
    [GtkChild] Gtk.Image toggle_image;

    public EditorSearchBox(Gtk.SourceView view)
    {
        this.view = view;
        this.buff = view.buffer as Gtk.SourceBuffer;
    }

    [GtkCallback]
    private void on_advanced_toggled()
    {
        bool now = !this.advanced_revealer.get_reveal_child();
        this.advanced_revealer.set_reveal_child(now);

        this.toggle_image.set_from_icon_name(
            (now) ? "go-down-symbolic" : "go-next-symbolic",
            Gtk.IconSize.MENU
        );
    }
}
