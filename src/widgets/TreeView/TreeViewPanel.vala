/* TreeViewPanel.vala
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

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/tree-view-panel.ui")]
public class Proton.TreeViewPanel : Gtk.Box, IModule {
    public weak Window win { get; protected set; }

    private HashTable<string, TreeView> tree_views;

    [GtkChild] Gtk.Box tree_views_box;
    [GtkChild] Gtk.Stack stack;

    construct {
        this.tree_views = new HashTable<string, TreeView>(str_hash, str_equal);
    }

    public TreeViewPanel(Window win) {
        Object(orientation: Gtk.Orientation.VERTICAL);
        this.win = win;

        this.win.workspaces.inserted.connect(this.on_workspace_inserted);
        this.win.workspaces.removed.connect(this.on_workspace_removed);
    }

    private void on_workspace_inserted(File f) {
        if (this.tree_views.contains(f.path)) {
            return;
        }
        //  this.add_tree_view(new TreeView(this.win, f));
        var tv = new TreeView(this.win, f);
        message("TreeView was just created, has %u references", tv.ref_count);
        this.add_tree_view(tv);
    }

    private void add_tree_view(TreeView tree_view) {
        this.tree_views.set(tree_view.root.path, tree_view);
        this.tree_views_box.pack_start(tree_view, false, true, 0);

        this.stack.visible_child_name = "main";
    }

    private void on_workspace_removed(File f) {
        if (!this.tree_views.contains(f.path)) {
            return;
        }
        this.remove_tree_view(f);
    }

    private void remove_tree_view(File f) {
        bool exists = false;
        var tv = this.tree_views.take(f.path, out exists);

        return_if_fail(exists);
        this.tree_views_box.remove(tv);
        message("On remove tv had %u references", tv.ref_count);
        //  delete tv;
        tv.destroy();
        message("On remove tv had %u references", (tv != null) ? tv.ref_count : 42);

        if (this.tree_views.size() == 0) {
            this.stack.visible_child_name = "empty";
        }
    }

    public TreeView? get_tree_view(string path) {
        return (this.tree_views.get(path));
    }

    [GtkCallback]
    private void open_folder_clicked() {
        var d = new Gtk.FileChooserDialog("Open folder", this.win,
                                          Gtk.FileChooserAction.SELECT_FOLDER,
                                          "Cancel", Gtk.ResponseType.CANCEL,
                                          "Open", Gtk.ResponseType.ACCEPT,
                                          null);
        int res = d.run();

        if (res == Gtk.ResponseType.ACCEPT) {
            this.win.workspaces.add(new File(d.get_filename()));
        }
        d.destroy();
    }
}
