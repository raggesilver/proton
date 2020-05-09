/* ArrayList.vala
 *
 * Copyright 2020 Paulo Queiroz
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
 */

/**
 * Proton.ArrayList is a simple wrapper for Gee.ArrayList that will emit
 * `inserted` upon data insertion and `removed` upon data deletion. It will also
 * trigger notify for the `size` field if it changes during add, insert, remove
 * and remove_at function calls.
 */

public class Proton.ArrayList<G> : Gee.ArrayList<G> {
    public signal void inserted(G item, int index);
    public signal void removed(G item, int index);

    /**
     * {@inheritDoc}
     */
    public override bool add(G item) {
        bool res = base.add(item);

        if (res) {
            this.inserted(item, this.size - 1);
            this.notify_property("size");
        }
        return (res);
    }

    /**
     * {@inheritDoc}
     */
    public override void insert(int index, G item) {
        base.insert(index, item);
        this.inserted(item, index);
        this.notify_property("size");
    }

    /**
     * {@inheritDoc}
     */
    public override bool remove(G item) {
        bool res = base.remove(item);

#if 0
        if (res) {
            // There is no need to notify here since I believe base.remove calls
            // remove_at, which does the job already.
        }
#endif

        return (res);
    }

    /**
     * {@inheritDoc}
     */
    public override G remove_at(int index) {
        int sz = this.size;
        G item = base.remove_at(index);

        if (sz != this.size) {
            this.removed(item, index);
            this.notify_property("size");
        }

        return (item);
    }
}
