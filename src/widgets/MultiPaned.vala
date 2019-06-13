/* MultiPaned.vala
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

public class Proton.MultiPaned : Dazzle.MultiPaned
{
    public MultiPaned(Gtk.Orientation orientation)
    {
        Object(orientation: orientation);
    }

    public override void add(Gtk.Widget widget)
    {
        base.add(widget);
        // var sizes = new Array<float>();
        var _children = new Array<Gtk.Widget>();

        // var total_size = 0;

        forall((w) => {
            _children.append_val(w);
            // float sz = (orientation == Gtk.Orientation.HORIZONTAL) ?
            //     w.get_allocated_width() :
            //     w.get_allocated_height();
            // sizes.append_val(sz);
            // total_size += sz;
        });

        // int sz = (orientation == Gtk.Orientation.HORIZONTAL) ?
        //     get_allocated_width() : get_allocated_height();

        // int ns = (int) (sz / _children.length);
        foreach (var c in _children.data)
        {
            if (orientation == Gtk.Orientation.HORIZONTAL)
                c.set_hexpand(true);
            else
                c.set_vexpand(true);
        }
    }
}
