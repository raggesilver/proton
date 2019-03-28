/* TreeView.vala
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
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

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/TreeView.ui")]
public class Proton.TreeView : Gtk.TreeView {

    public signal void selected(File file);
    public signal void renamed(string old, string _new);

    public File root { get; private set; }
    public Gtk.TreeSelection selection;

    private Gtk.TreeStore store;
    private Gtk.IconTheme icon_theme;
    private FileMonitor[] monitors = {};

    public TreeView(File root) {

        Object(activate_on_single_click: true,
               fixed_height_mode: true);

        this.root = root;
        // get_style_context ().add_class ("bg-color");
        icon_theme = Gtk.IconTheme.get_default();

        build_treeview();
        fill_tree(root, null);

        button_press_event.connect ((e) => {
            Gtk.TreePath path;
            Gtk.TreeViewColumn col;
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            int x, y;

            get_path_at_pos(
                (int)e.x, (int)e.y, out path, out col, out x, out y);

            if (path == null)
                return true;
            // Make sure the right iter is selected
            grab_focus();
            set_cursor(path, col, false);

            selection.get_selected(out model, out iter);

            if (e.button == 1)
                return left_button_clicked_row(model, iter);
            else if (e.button == 3)
                return right_button_clicked_row(model, iter, e);
            return false;
        });
    }

    public void refill() {
        store.clear();
        fill_tree(root, null);
    }

    void fill_tree(File _root, Gtk.TreeIter? parent) {
        try {
            Dir dir = Dir.open(_root.path);
            string? f = null;

            // Add monitor
            try {
                var m = _root.file.monitor_directory(FileMonitorFlags.WATCH_MOVES);
                m.changed.connect(on_changed);

                monitors += m;
            } catch {
                warning("Could not create monitor for %s\n", _root.path);
            }

            while ((f = dir.read_name()) != null) {
                string name = Path.build_filename(_root.path, f);

                // store.append(out current, parent);

                File ff = new File(name);
                /* ff.query_info_async.begin ("standard::icon", 0, Priority.DEFAULT, null, (obj, res) => {
                    FileInfo fi = ff.query_info_async.end (res);
                    Icon icon = fi.get_icon ();
                    var icinf = icon_theme.lookup_by_gicon (icon, 16, Gtk.IconLookupFlags.FORCE_SYMBOLIC);
                    store.set (current, 0, icinf.load_icon (), 1, ff.get_basename (), -1);
                }); */

                //  var img = new Gtk.Image.from_icon_name (
                    //  ((is_dir) ? "folder-symbolic" : "text-x-generic-symbolic"), Gtk.IconSize.MENU);
                //  img.show ();
                //  Gdk.Pixbuf ic = img.get_pixbuf ();
                //  store.set (current, 0, ic, 1, ff.get_basename (), -1);
                // store.set(current, 0, ff.name, -1);
                // current = ;
                Gtk.TreeIter current = _place_file(ff.name, parent);

                if (ff.is_directory)
                    fill_tree(ff, current);
            }

        } catch (FileError err) {
            error(err.message);
        }
    }

    void build_treeview() {
        //  store = new Gtk.TreeStore(2, typeof (Gdk.Pixbuf), typeof (string));
        store = new Gtk.TreeStore(1, typeof(string));
        set_model(store);

        //  insert_column_with_attributes (0, "", new Gtk.CellRendererPixbuf(), "pixbuf", 0, null);
        insert_column_with_attributes(
            0, "", new Gtk.CellRendererText(), "text", 0, null);

        store.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        store.set_sort_func(0, (mod, a, b) => {
            File fa = get_file_from_selection(mod, a);
            File fb = get_file_from_selection(mod, b);

            if (fa.is_directory && !fb.is_directory)
                return (-1);
            else if (fb.is_directory && !fa.is_directory)
                return (1);

            return (strcmp(fa.name, fb.name));
        });

        selection = get_selection();
        get_column(0).set_sizing(Gtk.TreeViewColumnSizing.AUTOSIZE);
        set_headers_visible(false);
        // selection.changed.connect (() => {});
    }

    private void on_changed(GLib.File f, GLib.File? of, FileMonitorEvent e) {

        var ff = new File(f.get_path());

        Gtk.TreeIter it;
        if (e == FileMonitorEvent.CREATED) {
            it = _place_file(f.get_path().offset(root.path.length + 1));
            if (ff.is_directory)
                fill_tree(ff, it);
        }
        else if (e == FileMonitorEvent.MOVED_IN) {
            it = _place_file(of.get_path().offset(root.path.length + 1));
            ff = new File(of.get_path());
            if (ff.exists && ff.is_directory)
                fill_tree(ff, it);

            renamed(of.get_path(), f.get_path());
        }
        else if (e == FileMonitorEvent.MOVED_OUT) {
            _remove_file(f.get_path().offset(root.path.length + 1));
            renamed(f.get_path(), of.get_path());
        }
        else if (e == FileMonitorEvent.RENAMED) {
            _remove_file(f.get_path().offset(root.path.length + 1));
            _place_file(of.get_path().offset(root.path.length + 1));
            renamed(f.get_path(), of.get_path());
        }
        else if (e == FileMonitorEvent.DELETED)
            _remove_file(f.get_path().offset(root.path.length + 1));
    }

    Gtk.TreeIter _place_file(string path, Gtk.TreeIter? _parent = null) {

        var path_arr = path.split("/");
        Gtk.TreeIter current = {};

        // If there is no parent or there is a child check the current level for
        // the target, if it doesn't exist, crete it (outside the if)
        if (_parent == null || this.model.iter_children(out current, _parent)) {

            bool b = true;

            if (_parent == null)
                b = this.model.get_iter_first(out current);

            while(b) {
                string s;
                this.model.get(current, 0, out s, -1);

                // If the target exists, deal with it maybe not being the last
                // target and return
                if (s == path_arr[0]) {
                    if(path_arr.length > 1)
                        return _place_file(
                            path.offset(path_arr[0].length + 1), current);
                    return current;
                }

                b = this.model.iter_next(ref current);
            }
        }

        // The target doesn't exist yet, so create it
        store.append(out current, _parent);
        store.set(current, 0, path_arr[0], -1);

        if(path_arr.length > 1)
            return _place_file(path.offset(path_arr[0].length + 1), current);
        else
            return current;
    }

    void _remove_file(string path, Gtk.TreeIter? _parent = null) {

        var path_arr = path.split("/");
        Gtk.TreeIter current = {};

        // If there is no parent or there is a child check the current level for
        // the target, if it doesn't exist, crete it (outside the if)
        if (_parent == null || this.model.iter_children(out current, _parent)) {
            if (_parent == null)
                this.model.get_iter_first(out current);

            do {
                string s;
                this.model.get(current, 0, out s, -1);

                // If the target exists, deal with it maybe not being the last
                // target and return
                if (s == path_arr[0]) {
                    if(path_arr.length > 1)
                        _remove_file(
                            path.offset(path_arr[0].length + 1), current);
                    else
                            store.remove(ref current);
                    return ;
                }

            } while (this.model.iter_next(ref current));
        }
    }

    public File get_file_from_selection(Gtk.TreeModel model,
                                        Gtk.TreeIter current)
    {
        string fullpath = "";

        bool has_parent = true;
        while (has_parent) {
            string partial;
            model.get(current, 0, out partial);
            fullpath = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S,
                                            partial,
                                            fullpath);
            has_parent = model.iter_parent(out current, current);
        }

        // Abspath
        if (this.root == null)
            error("No root");
        fullpath = Path.build_filename(root.path, fullpath);
        return (new File(fullpath));
    }

    bool left_button_clicked_row(Gtk.TreeModel model,
                                 Gtk.TreeIter current)
    {
        // Emit the selected signal
        var f = get_file_from_selection(model, current);
        if (f.is_directory) {
            var path = model.get_path(current);

            if (is_row_expanded(path))
                collapse_row(path);
            else
                expand_row(path, false);

        }
        selected(f);

        return false;
    }

    // FIXME change this for a "get_instance" model
    // TODO change from menu to a Gtk.Popover
    bool right_button_clicked_row(Gtk.TreeModel model,
                                  Gtk.TreeIter current,
                                  Gdk.Event e)
    {
        var menu = new Gtk.Menu();

        Gtk.MenuItem menu_item;

        // File ff = get_file_from_selection(model, current);
        // if (ff.is_directory) {
        // }

        menu_item = new Gtk.MenuItem.with_label("New File");
        menu.add(menu_item);

        menu_item = new Gtk.MenuItem.with_label("New Folder");
        menu.add(menu_item);

        var sep = new Gtk.SeparatorMenuItem();
        menu.add(sep);

        menu_item = new Gtk.MenuItem.with_label("Rename");
        menu.add(menu_item);

        menu_item = new Gtk.MenuItem.with_label("Delete");
        menu.add(menu_item);

        menu.show_all();
        menu.attach_to_widget(this, null);
        menu.popup_at_pointer(e);
        return false;
    }
}

