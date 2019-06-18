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

internal class Proton.Status
{
    public uint                             id { get; private set; }
    public StatusBox.Priority               p  { get; set; }
    public weak StatusBox.StatusCallback    cb { get; private set; }

    public Status(uint id, StatusBox.StatusCallback cb, StatusBox.Priority p)
    {
        this.id = id;
        this.p = p;
        this.cb = cb;
    }
}

/*
** TODO: Proton.Status should be public, Stauts.cb should be modifiable,
** add_status should return a Proton.Status and the field id would be no longer
** necessary.
** TODO: We are also missing `remove_status`, `display_now`, and some sort of
** permanent message that will be presented until the Status signals it's ok to
** continue the cyle.
** FIXME: This design doesn't support any other kind of widget, maybe the
** Status.cb should return a Gtk.Widget that would be added to the stack
** either directly for full control or in some kind of container.
** TODO: StatusBox is supposed to be clickable and to have a Gtk.Popover at the
** bottom. For this to happen we might have to change the base class from
** Gtk.Box to Gtk.EventBox, create new CSS rules for :hover and :active (if
** active is actually available) and trigger a manual Gtk.Popover.popup()
** FIXME: The Gtk.Popover for Proton.StatusBox needs design
*/

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/status_box.ui")]
public class Proton.StatusBox : Gtk.Box
{
    public delegate string StatusCallback();

    public enum Priority
    {
        LOW = 3,
        MEDIUM = 6,
        HIGH = 10
    }

    [GtkChild]
    Gtk.Stack       stack;

    Gtk.Label       label;
    Gtk.Label       tmp_label;
    List<Status>    status_list = new List<Status>();

    weak Window     window;
    weak Status     current_status;
    uint            cycle_id;

    public StatusBox(Window _win)
    {
        window = _win;

        label = new Gtk.Label(null);
        label.xalign = 0;

        tmp_label = new Gtk.Label(null);
        tmp_label.xalign = 0;

        stack.add_named(label, "lbl");
        stack.add_named(tmp_label, "tmp");

        show_all();

        add_status(() => {
            return (@"Project: $(window.root.name)");
        }, Priority.HIGH);

        start_cycle();
    }

    static uint id;
    public uint add_status(StatusCallback cb, Priority p = Priority.MEDIUM)
    {
        var s = new Status(id++, cb, p);
        status_list.append(s);

        return (id - 1);
    }

    void start_cycle()
    {
        current_status = status_list.first().data;
        cycle_step();
    }

    bool cycle_step()
    {
        tmp_label.label = label.label;
        stack.set_visible_child_full("tmp", Gtk.StackTransitionType.NONE);

        var i = status_list.index(current_status) + 1;
        if (i >= status_list.length())
            i = 0;

        current_status = status_list.nth(i).data;

        label.label = current_status.cb();
        stack.set_visible_child(label);

        cycle_id = Timeout.add_seconds(current_status.p, cycle_step);
        return (false);
    }
}
