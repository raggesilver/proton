/* StatusBox.vala
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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/status_box.ui")]
public class Proton.StatusBox : Gtk.Box
{
    [GtkChild]
    Gtk.Stack stack;

    [GtkChild]
    Gtk.Label filename;

    public Gtk.Label project_name { get; protected set; }
    public Gtk.Label status { get; protected set; }

    string[] labels = {"project_name", "status"};
    int      label_index = 0;

    uint cycle_id;

    public StatusBox(Window _win)
    {
        project_name = new Gtk.Label(@"Project: $(_win.root.name)");
        status = new Gtk.Label("Status: Ok");

        project_name.xalign = status.xalign = 0;
        filename.xalign = 1;

        stack.add_named(project_name, "project_name");
        stack.add_named(status, "status");

        show_all();

        start_cycle();
    }

    public void set_filename(string name)
    {
        filename.set_text(name);
    }

    void start_cycle()
    {
        cycle_id = Timeout.add_seconds(5, cycle_step);
    }

    bool cycle_step()
    {
        label_index = (label_index + 1) % labels.length;
        stack.set_visible_child_name(labels[label_index]);
        cycle_id = Timeout.add_seconds(5, cycle_step);
        return (false);
    }
}
