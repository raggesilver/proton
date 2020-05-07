/* TreeView.vala
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

public class Proton.TreeView : Gtk.TreeView, IModule {
    public weak Window win { get; protected set; }

    private new Gtk.TreeStore model { get; set; }

    construct {
        this.model = new Gtk.TreeStore.newv({ typeof(TreeViewItem) });

        this.activate_on_single_click = true;
        this.headers_visible = false;
        this.show_expanders = false;
        this.level_indentation = 18;
    }

    public TreeView (Window win) {
        this.win = win;
        this.show_all();
    }
}
