/* Container.vala
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

public class Proton.Container : Gtk.Stack {

    public  Gtk.Widget  widget;
    private Gtk.Spinner spinner;

    private bool _working { get; set; default = false; }
    public  bool  working { get { return _working; } }

    public Container(Gtk.Widget w, bool working = false) {
        widget = w;
        _working = working;

        spinner = new Gtk.Spinner ();
        spinner.start ();
        spinner.show ();

        add_named (widget, "widget");
        add_named (spinner, "spinner");

        set_working (_working);
        show ();
    }

    public Container.with_scroller (Gtk.Widget w, bool working = false) {
        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.show ();
        scroll.add (w);
        this(scroll, working);
    }

    public void set_working(bool working) {
        _working = working;
        set_visible_child_name (_working ? "spinner" : "widget");
    }
}

