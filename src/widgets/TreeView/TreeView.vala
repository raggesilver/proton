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

const int INDENTATION_LEVEL = 18;
// TreeView pixel renderer configuration
const int PIX_YPAD = 3;
const int PIX_XPAD = 8;
const int PIX_WIDTH = 40;
const float PIX_XALIGN = 1f;

public class Proton.TreeView : Gtk.TreeView, IModule {
    // Signal emited when a file (not dir) is selected
    public signal void changed(File f);
    // Basically the same as
    // https://valadoc.org/gio-2.0/GLib.FileMonitor.changed.html but may be
    // emitted from any monitor. The parameters are slightly different, event
    // comes first and file objects are not `GLib.File`s but `Proton.File`s
    public signal void monitor_event(FileMonitorEvent e, File f, File? of);

    public weak Window win { get; protected set; }
    public File root { get; private set; }
    public TreeViewItem? selected { get; private set; }

    private new Gtk.TreeStore model { get; set; }

    private HashTable<string, FileMonitor> monitors;

    //  private Mutex mut = Mutex();
    private Gtk.TreeViewColumn col;
    private Gtk.CellRendererPixbuf pxb;
    private Gtk.CellRendererText txt;

    construct {
        this.model = new Gtk.TreeStore.newv({ typeof(TreeViewItem) });

        this.activate_on_single_click = true;
        this.headers_visible = false;
        this.show_expanders = false;
        this.level_indentation = INDENTATION_LEVEL;

        this.col = new Gtk.TreeViewColumn();
        this.pxb = new Gtk.CellRendererPixbuf();
        this.txt = new Gtk.CellRendererText();

        this.col.pack_start(this.pxb, false);
        this.col.pack_start(this.txt, true);

        this.pxb.ypad = this.txt.ypad = PIX_YPAD;

        this.pxb.xpad = PIX_XPAD;
        this.pxb.xalign = PIX_XALIGN;
        this.pxb.width = PIX_WIDTH;

        this.col.set_cell_data_func(this.pxb, this.cell_pxb_render_function);
        this.col.set_cell_data_func(this.txt, this.cell_txt_render_function);

        this.col.set_sizing(Gtk.TreeViewColumnSizing.AUTOSIZE);

        this.model.set_sort_func(0, TreeView.sort_function);
        this.model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        this.row_activated.connect(this.on_row_activated);

        this.set_model(this.model);
        this.append_column(this.col);

        this.monitors = new HashTable<string, FileMonitor>(str_hash, str_equal);
    }

    public TreeView (Window win, File root) {
        this.win = win;
        this.root = root;
        this.show_all();

        this.col.set_title(root.name);

        // Create the root element manually
        var it = Gtk.TreeIter();
        var item = new TreeViewItem(root, this);
        item.is_populated = true;
        this.model.append(out it, null);
        this.model.set(it, 0, item, -1);

        // Wait for root element to be populated, then expand it
        this.build.begin(this.root, it, (_, res) => {
            this.build.end(res);
            this.expand_row(this.model.get_path(it), true);
        });

        this.destroy.connect(this.on_destroy);
    }

    private void on_destroy() {
        // Gotta free these refs
        this.col.set_cell_data_func(this.pxb, null);
        this.col.set_cell_data_func(this.txt, null);

        this.monitors.foreach_remove((k, v) => {
            v.cancel();
            return (true);
        });
    }

    ~TreeView() {
        message("TreeView destroyed");
    }

    private void on_monitor_changed(Gtk.TreeIter? parent,
                                    GLib.File file,
                                    GLib.File? other_file,
                                    FileMonitorEvent e)
    {
        // Not likely to happen
        if (parent == null) {
            return;
        }

        var f = new File(file.get_path());
        var of = (other_file == null) ? null : new File(other_file.get_path());
        var folderItem = TreeViewItem.get_from_model(this.model, parent, 0);

        message("Monitor event %s in %s", e.to_string(), folderItem.file.path);

        if (e == FileMonitorEvent.CREATED || e == FileMonitorEvent.MOVED_IN) {
            this.t_insert_file(f, parent);
        }
        else if (
            e == FileMonitorEvent.DELETED
            || e == FileMonitorEvent.MOVED_OUT
        ) {
            this.remove_file(f, parent);
        }
        else if (e == FileMonitorEvent.RENAMED) {
            message("Renamed %s %s", f.path, of.path);
        }

        this.monitor_event(e, f, of);
    }

    private void cell_txt_render_function(Gtk.CellLayout _cell_layout,
                                          Gtk.CellRenderer cell,
                                          Gtk.TreeModel tree_model,
                                          Gtk.TreeIter iter)
    {
        var item = TreeViewItem.get_from_model(tree_model, iter, 0);
        cell.set_property("text", item.file.name);
    }

    private void cell_pxb_render_function(Gtk.CellLayout _cell_layout,
                                          Gtk.CellRenderer cell,
                                          Gtk.TreeModel tree_model,
                                          Gtk.TreeIter iter)
    {
        var item = TreeViewItem.get_from_model(tree_model, iter, 0);

        if (item.is_directory) {
            cell.set_property("icon-name", (item.is_expanded) ?
                "folder-open-symbolic" : "folder-symbolic");
        }
        else {
            cell.set_property("icon-name", "text-x-generic-symbolic");
        }
    }

    private static int sort_function(Gtk.TreeModel tree_model,
                                     Gtk.TreeIter _a,
                                     Gtk.TreeIter _b)
    {
        var a = TreeViewItem.get_from_model(tree_model, _a, 0);
        var b = TreeViewItem.get_from_model(tree_model, _b, 0);

        if (a.is_directory && !b.is_directory) {
            return (-1);
        }
        if (b.is_directory && !a.is_directory) {
            return (1);
        }

        return (a.file.name.ascii_casecmp(b.file.name));
    }

    private async void build(File _root, Gtk.TreeIter? parent = null) {
        // this.disable_sorting();

        new Thread<bool>("proton-tree-view-build", () => {
            this.t_build(_root, parent);
            Idle.add(this.build.callback);
            return (Source.REMOVE);
        });

        yield;

        // this.enable_sorting();
    }

    private void t_build(File _root, Gtk.TreeIter? parent) {
        try {
            string? fname = null;
            var     dir = Dir.open(_root.path);
            File    f;

            var m = _root.file.monitor_directory(FileMonitorFlags.WATCH_MOVES);
            this.monitors.set(_root.path, m);

            m.changed.connect((f, of, e) => {
                this.on_monitor_changed(parent, f, of, e);
            });

            while ((fname = dir.read_name()) != null) {
                f = new File(Path.build_filename(_root.path, fname, null));
                this.t_insert_file(f, parent);
            }
        }
        catch (Error e) {
            warning(e.message);
        }
    }

    private void t_insert_file(File f, Gtk.TreeIter? parent = null) {
        var it = Gtk.TreeIter();
        var item = new TreeViewItem(f, this);

        Idle.add(() => {
            this.model.append(out it, parent);
            this.model.set(it, 0, item, -1);
            return (Source.REMOVE);
        });
    }

    private Gtk.TreeIter? find_iter_by_file(File f, Gtk.TreeIter parent) {
        Gtk.TreeIter it;
        TreeViewItem item;

        for (int i = 0;; i++) {
            if (!this.model.iter_nth_child(out it, parent, i)) {
                return (null);
            }
            this.model.get(it, 0, out item, -1);
            if (File.equ(f, item.file)) {
                return (it);
            }
        }
    }

    private void remove_file_by_iter(Gtk.TreeIter it) {
        Gtk.TreeIter subit;
        TreeViewItem item;

        item = TreeViewItem.get_from_model(this.model, it, 0);
        if (this.model.iter_has_child(it)) {
            for (int i = 0;; i++) {
                if (!this.model.iter_nth_child(out subit, it, i)) {
                    break;
                }
                this.remove_file_by_iter(subit);
            }
            var mon = this.monitors.get(item.file.path);
            if (mon != null) {
                mon.cancel();
                this.monitors.remove(item.file.path);
            }
        }
        this.model.remove(ref it);
    }

    private void remove_file(File f, Gtk.TreeIter? parent) {
        Gtk.TreeIter? it = null;

        if (parent == null && this.model.get_iter_from_string(out it, "0")) {
            ;
        }
        else {
            it = this.find_iter_by_file(f, parent);
        }

        return_if_fail(it != null);

        this.remove_file_by_iter(it);
    }

    private void on_row_activated(Gtk.TreePath path,
                                  Gtk.TreeViewColumn column)
    {
        Gtk.TreeIter iter;
        TreeViewItem item;
        bool exp;

        this.model.get_iter_from_string(out iter, path.to_string());
        item = TreeViewItem.get_from_model(this.model, iter, 0);
        exp = this.is_row_expanded(path) || item.is_expanded;

        if (item.is_directory) {
            if (!item.is_populated && !exp) {
                item.is_populated = true;
                item.is_expanded = true;
                this.build.begin(item.file, iter, (_, res) => {
                    this.build.end(res);
                    this.expand_row(path, false);
                });
            }
            else {
                if (exp) {
                    this.collapse_children(iter);
                    this.collapse_row(path);
                }
                else {
                    this.expand_row(path, false);
                }
                item.is_expanded = !exp;
            }
        }
        else {
            // Only emited with files
            this.changed(item.file);
        }
        this.selected = item;
    }

    private bool collapse_children(Gtk.TreeIter parent) {
        Gtk.TreeIter it;
        TreeViewItem item;
        bool         collapsed = false;

        for (int i = 0;; i++) {
            if (!this.model.iter_nth_child(out it, parent, i)) {
                break;
            }
            item = TreeViewItem.get_from_model(this.model, it, 0);
            if (item.is_expanded) {
                this.collapse_children(it);
                collapsed = true;
            }
            item.is_expanded = false;
        }
        return (collapsed);
    }
}
