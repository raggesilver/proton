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

public class Proton.Status
{
    public StatusBox.Priority               p  { get; set; }
    public weak StatusBox.StatusCallback    cb { get; set; }

    public Status(StatusBox.StatusCallback cb, StatusBox.Priority p)
    {
        this.p = p;
        this.cb = cb;
    }
}

/*
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
public class Proton.StatusBox : Gtk.EventBox
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

    [GtkChild]
    Gtk.Box         box;

    [GtkChild]
    Gtk.Popover     popover;

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

        add_status(new Status(() => {
            return (@"Project: $(window.root.name)");
        }, Priority.LOW));

        start_cycle();

        this.event.connect((e) => {

            if (e.type == Gdk.EventType.ENTER_NOTIFY)
            {
                this.box.get_style_context().add_class("hover");
            }
            else if (e.type == Gdk.EventType.LEAVE_NOTIFY)
            {
                this.box.get_style_context().remove_class("hover");
            }
            // FIXME: The popover needs UI and functionality design
            /* else if (e.type == Gdk.EventType.BUTTON_RELEASE)
            {
                this.popover.popup();
                return (true);
            } */

            return (false);
        });

        this.popover.closed.connect(() => {
            this.box.get_style_context().remove_class("click");
        });

        this.popover.notify["visible"].connect(() => {
            if (this.popover.visible)
                this.box.get_style_context().add_class("click");
            else
                this.box.get_style_context().remove_class("click");
        });
    }

    public void show_status(Status s)
    {
        Source.remove(this.cycle_id);
        this.set_status(s);
        Timeout.add_seconds(s.p, this.cycle_step);
    }

    public void add_status(Status s)
    {
        status_list.append(s);
    }

    public void add_status_show(Status s)
    {
        this.add_status(s);
        this.show_status(s);
    }

    public void remove_status(Status status)
    {
        if (status == this.current_status)
        {
            Source.remove(cycle_id);
        }

        this.status_list.remove(status);
        this.cycle_step();
    }

    void start_cycle()
    {
        current_status = status_list.first().data;
        this.cycle_step();
    }

    bool cycle_step()
    {
        var i = status_list.index(current_status) + 1;
        if (i >= status_list.length())
            i = 0;

        current_status = status_list.nth(i).data;
        set_status(current_status);

        cycle_id = Timeout.add_seconds(current_status.p, this.cycle_step);
        return (false);
    }

    void set_status(Status status)
    {
        tmp_label.label = label.label;
        stack.set_visible_child_full("tmp", Gtk.StackTransitionType.NONE);

        label.label = status.cb();
        stack.set_visible_child(label);
    }
}
