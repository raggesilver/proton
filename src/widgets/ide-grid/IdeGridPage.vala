/* IdeGridPage.vala
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

/*
** Widget that will be added to IdeGridStack.popover.
*/

public class Proton.IdeGridPagePopEntry : Gtk.ListBoxRow
{
    public Gtk.Label    label { get; private set; }
    public Gtk.Button   close_button { get; private set; }
    public IdeGridPage  page { get; private set; }

    public IdeGridPagePopEntry(IdeGridPage _page)
    {
        page = _page;
        label = new Gtk.Label(null);
        page.notify["title"].connect(() => {
            label.label = page.title;
        });
        close_button = new Gtk.Button.from_icon_name("window-close-symbolic",
                                                     Gtk.IconSize.MENU);
        close_button.set_relief(Gtk.ReliefStyle.NONE);
        close_button.get_style_context().add_class("close");

        var b = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        b.pack_start(label, true, true, 0);
        b.pack_end(close_button, false, false, 0);

        add(b);

        show_all();
    }
}

public abstract class Proton.IdeGridPage : Gtk.Box
{
    public signal void focused();
    public signal void style_changed(string? bg, string? fg);

    public string? bg { get; set; default = null; }
    public string? fg { get; set; default = null; }

    public string title { get; set; }
    public IdeGridPagePopEntry pop_entry { get; private set; }

    construct
    {
        pop_entry = new IdeGridPagePopEntry(this);
        pop_entry.close_button.clicked.connect(() => {
            destroy();
        });
        notify["bg"].connect(() => {
            style_changed(bg, fg);
        });
        notify["fg"].connect(() => {
            style_changed(bg, fg);
        });
    }

    public override void destroy()
    {
        pop_entry.destroy();
        base.destroy();
    }
}

public class Proton.DummyPage : Proton.IdeGridPage
{
    static int _id;

    public DummyPage()
    {
        title = "Dummy %d".printf(_id++);
        var l = new Gtk.Label("Content %d".printf(_id - 1));
        l.xalign = 0.5f;
        pack_start(l, true, true, 0);
        show_all();
    }
}
