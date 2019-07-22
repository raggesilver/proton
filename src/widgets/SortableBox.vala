/* SortableBox.vala
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

public class Proton.SortableBox : Gtk.Box
{
    public delegate int             PCompareFunction(void *a, void *b);
    public delegate SortableBox?    PIsSortableFunction(void *a);

    public SortableBox(Gtk.Orientation orientation, int spacing)
    {
        Object(orientation: orientation,
               spacing: spacing);
    }

    public void sort(PCompareFunction       comp,
                     PIsSortableFunction?   is_sort,
                     bool                   do_recursion = true)
    {
#if DEBUG_SORTABLE_BOX
        var t = new Timer();
        t.start();
#endif

        var lst = get_children();
        var len = lst.length();

        if (len == 0)
            return ;

        lst.sort((CompareFunc<void *>)comp);

        for (uint i = 0; i < len; i++)
            reorder_child(lst.nth_data(i), (int)i);

#if DEBUG_SORTABLE_BOX
        t.stop();
        ulong mc = 0;
        t.elapsed(out mc);
        debug("[SortableBox] Sort ended in %lu microseconds", mc);
#endif

        if (is_sort != null && do_recursion)
        {
            for (uint i = 0; i < len; i++)
            {
                var s = is_sort(lst.nth_data(i));
                if (s != null)
                    s.sort(comp, is_sort);
            }
        }
    }
}
