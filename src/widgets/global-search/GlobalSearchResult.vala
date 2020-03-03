/* GlobalSearchResult.vala
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

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/global_search_result.ui")]
public class Proton.GlobalSearchResult : Gtk.Box
{
    [GtkChild] private Gtk.Revealer revealer;

    public GlobalSearchResult() {}

    [GtkCallback]
    private void on_replace_button_clicked() {}

    [GtkCallback]
    private void on_remove_button_clicked() {}

    [GtkCallback]
    private bool on_focus_in_event(Gdk.EventFocus e)
    {
        (void)e;
        this.revealer.set_reveal_child(true);
        return (false);
    }

    [GtkCallback]
    private bool on_focus_out_event(Gdk.EventFocus e)
    {
        (void)e;
        this.revealer.set_reveal_child(false);
        return (false);
    }
}
