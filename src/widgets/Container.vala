/* Container.vala
 *
 * Copyright 2019 Paulo Queiroz <unknown@domain.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
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

