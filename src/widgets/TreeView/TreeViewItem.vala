/* TreeViewItem.vala
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

public class Proton.TreeViewItem : Object {
    public File file { get; protected set; }

    public bool is_directory {
        get {
            return (this.file.is_directory);
        }
    }

    public weak TreeView tree_view { get; private set; }
    public bool is_populated { get; set; default = false; }
    public bool is_expanded { get; set; default = false; }

    public TreeViewItem(File file, TreeView tree_view) {
        this.file = file;
        this.tree_view = tree_view;
    }

    public inline TreeViewItem.from_path(string path) {
        base(new File(path));
    }

    ~TreeViewItem() {
        message("I was destroyed");
    }

    public static TreeViewItem get_from_model(Gtk.TreeModel model,
                                              Gtk.TreeIter iter,
                                              int index)
    {
        Value val;

        model.get_value(iter, index, out val);
        return ((TreeViewItem)val);
    }
}
