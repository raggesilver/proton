/* EditorGridPage.vala
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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/editor_grid_page.ui")]
public class Proton.EditorGridPage : Gtk.Box
{
    public signal void page_focused();

    [GtkChild]
    public Gtk.Button title_button { get; protected set; }

    [GtkChild]
    public Gtk.ScrolledWindow scrolled { get; protected set; }

    [GtkChild]
    public Gtk.Box header { get; protected set; }

    [GtkChild]
    public Gtk.Button close_button { get; protected set; }

    [GtkChild]
    public Gtk.ModelButton pop_title_button { get; protected set; }

    [GtkChild]
    public Gtk.Button pop_close_button { get; protected set; }

    [GtkChild]
    public Gtk.Box pop_pages_box_item { get; protected set; }

    public string title { get; protected set; }

    public EditorGridPage()
    {
        close_button.clicked.connect(() => {
            destroy();
        });

        pop_close_button.clicked.connect(() => {
            destroy();
        });

        pop_title_button.clicked.connect(() => {
            page_focused();
        });
    }

    public override void destroy()
    {
        pop_pages_box_item.destroy();
        base.destroy();
    }
}