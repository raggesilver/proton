/* Loadable.vala
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

public class Proton.Loadable<T> : Gtk.Overlay
{
    public bool       loading { get; set; default = false; }
    public T          content { get; set; }

    Gtk.Spinner spinner;

    public Loadable(T content)
    {
        Object(content: content);

        spinner = new Gtk.Spinner();
        spinner.start();

        add_overlay(spinner);
        set_overlay_pass_through(spinner, false);

        add(content as Gtk.Widget);

        notify["loading"].connect(loading_changed);

        get_style_context().add_class("loadable");
    }

    void loading_changed()
    {
        spinner.set_visible(loading);
    }
}

public class Proton.Sortable : Proton.Loadable<Proton.SortableBox>
{
    public delegate int PCompareFunction(void *a, void *b);
    public delegate SortableBox? PIsSortableFunction(void *a);

    public Sortable(Gtk.Orientation orientation, int spacing)
    {
        var _content = new SortableBox(orientation, spacing);

        base(_content);

        content.show();
        show();
    }

    public void sort(PCompareFunction comp,
                     PIsSortableFunction? is_sort,
                     bool do_recursion = true)
    {
        content.sort(comp, is_sort, do_recursion);
    }

    public void pack_start(Gtk.Widget w, bool expand, bool fill, int spacing)
    {
        content.pack_start(w, expand, fill, spacing);
    }

    public void pack_end(Gtk.Widget w, bool expand, bool fill, int spacing)
    {
        content.pack_end(w, expand, fill, spacing);
    }

    public new void add(Gtk.Widget w)
    {
        content.add(w);
    }
}
