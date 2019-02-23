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
    public Gtk.TreeSelection selection;
    private Gtk.TreeStore store;
    private Gtk.IconTheme icon_theme;

    public signal void selected (GLib.File file);

    public TreeView (GLib.File root) {

        Object (activate_on_single_click: true,
                fixed_height_mode: true);

        // get_style_context ().add_class ("bg-color");
        icon_theme = Gtk.IconTheme.get_default ();

        build_treeview ();
        fill_tree (root, null);

        button_press_event.connect ((e) => {

            // Make sure the right iter is selected

            Gtk.TreePath path;
            Gtk.TreeViewColumn col;
            Gtk.TreeIter iter;
            Gtk.TreeModel model;
            int x, y;
            get_path_at_pos ((int)e.x, (int)e.y, out path, out col, out x, out y);
            if (path == null)
                return true;
            grab_focus ();
            set_cursor (path, col, false);

            selection.get_selected (out model, out iter);

            if (e.button == 1)
                return left_button_clicked_row (root, model, iter);
            else if (e.button == 3)
                return right_button_clicked_row (root, model, iter, e);
            return false;
        });
    }

    void fill_tree(GLib.File _root, Gtk.TreeIter? parent) {
        try {
            Dir dir = Dir.open (_root.get_path ());
            string? f = null;

            while ((f = dir.read_name ()) != null) {
                string name = Path.build_filename (_root.get_path (), f);

                Gtk.TreeIter current;
                store.append (out current, parent);

                GLib.File ff = GLib.File.new_for_path (name);
                /* ff.query_info_async.begin ("standard::icon", 0, Priority.DEFAULT, null, (obj, res) => {
                    FileInfo fi = ff.query_info_async.end (res);
                    Icon icon = fi.get_icon ();
                    var icinf = icon_theme.lookup_by_gicon (icon, 16, Gtk.IconLookupFlags.FORCE_SYMBOLIC);
                    store.set (current, 0, icinf.load_icon (), 1, ff.get_basename (), -1);
                }); */

                store.set (current, 0, ff.get_basename (), -1);


                if (ff.query_file_type (0) == FileType.DIRECTORY)
                    fill_tree (ff, current);
            }

        } catch (FileError err) {
            print(err.message);
            Process.exit (1);
        }
    }

    void build_treeview() {
        // store = new Gtk.TreeStore(2, typeof (Gdk.Pixbuf), typeof (string));
        store = new Gtk.TreeStore(1, typeof (string));
        set_model (store);

        // insert_column_with_attributes (0, "", new Gtk.CellRendererPixbuf(), "pixbuf", 0, null);
        insert_column_with_attributes (0, "", new Gtk.CellRendererText(), "text", 0, null);

        selection = get_selection ();
        get_column (0).set_sizing (Gtk.TreeViewColumnSizing.AUTOSIZE);
        set_headers_visible (false);
        // selection.changed.connect (() => {});
    }

    public GLib.File get_file_from_selection (GLib.File root,
                                              Gtk.TreeModel model,
                                              Gtk.TreeIter current)
    {
        string fullpath = "";

        bool has_parent = true;
        while (has_parent) {
            string partial;
            model.get (current, 0, out partial);
            fullpath = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
                                             partial,
                                             fullpath);
            has_parent = model.iter_parent (out current, current);
        }

        // Abspath
        fullpath = Path.build_filename (root.get_path (), fullpath);
        return GLib.File.new_for_path (fullpath);
    }

    bool left_button_clicked_row (GLib.File root,
                                  Gtk.TreeModel model,
                                  Gtk.TreeIter current)
    {
        // Emit the selected signal
        var f = get_file_from_selection (root, model, current);
        if (f.query_file_type (0) == FileType.DIRECTORY) {
            var path = model.get_path (current);
            if (is_row_expanded (path))
                collapse_row (path);
            else
                expand_row (path, false);

        }
        selected (f);

        return false;
    }

    bool right_button_clicked_row (GLib.File root,
                                   Gtk.TreeModel model,
                                   Gtk.TreeIter current,
                                   Gdk.Event e)
    {
        var menu = new Gtk.Menu ();

        Gtk.MenuItem menu_item;

        /*File ff = get_file_from_selection (root, model, current);
        if (ff.query_file_type (0) == FileType.DIRECTORY) {

        }*/

        menu_item = new Gtk.MenuItem.with_label ("New File");
        menu.add (menu_item);

        menu_item = new Gtk.MenuItem.with_label ("New Folder");
        menu.add (menu_item);

        var sep = new Gtk.SeparatorMenuItem ();
        menu.add (sep);

        menu_item = new Gtk.MenuItem.with_label ("Rename");
        menu.add (menu_item);

        menu_item = new Gtk.MenuItem.with_label ("Delete");
        menu.add (menu_item);

        menu.show_all ();
        menu.attach_to_widget (this, null);
        menu.popup_at_pointer (e);
        return false;
    }
}

