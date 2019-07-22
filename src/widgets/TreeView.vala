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

public class Proton.TreeItem : Gtk.Box
{
    public signal bool left_click();
    public signal bool right_click();
    public signal bool populate(SourceFunc f);

    public File         file            { get; protected set; }
    public SortableBox  container       { get; protected set; default = null; }
    public bool         is_populated    { get; protected set; default = false; }

    public bool         is_directory {
        get {
            return (file.is_directory);
        }
    }

    private Gtk.Label   label;

    /*
    ** TreeIcon is a new class defined in FileIconProvider that contains a
    ** Gtk.Image and more information on the icon.
    */
    private TreeIcon    icon;

    private Gtk.Box     box;
    private uint        level;

    public TreeItem(File file, uint level = 0)
    {
        Object(orientation: Gtk.Orientation.VERTICAL,
               spacing: 2);

        get_style_context().add_class("treeitem");

        this.file = file;
        this.level = level;

        build_ui();
    }

    public TreeItem.from_path(string s, uint level = 0)
    {
        this(new File(s), level);
    }

    public void toggle_expanded()
    {
        // Only folders can be expanded
        if (!this.is_directory)
            return ;

        bool s = !this.container.get_visible();

        this.icon.is_expanded = s;
        this.container.set_visible(s);
    }

    public void set_modified(bool modified)
    {
        if (modified)
            label.set_label(file.name + " •");
        else
            label.set_label(file.name);
    }

    public void do_sort()
    {
        container.sort(TreeItem.tree_sort_function,
                       TreeItem.tree_is_sortable_function);
    }

    private void build_ui()
    {
        this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        var eb = new Gtk.EventBox();
        eb.button_release_event.connect((e) => {
            if (e.button == 1)
            {
                if (!this.is_directory || this.is_populated)
                {
                    return (this.left_click());
                }
                else
                {
                    populate(() => {
                        this.is_populated = true;
                        this.left_click();
                        return (false);
                    });
                    return (false);
                }
            }
            else if (e.button == 3)
            {
                return (this.right_click());
            }

            return (false);
        });

        eb.add(this.box);

        this.box.set_size_request(-1, 28);

        var ic_provider = ProtonIconProvider.get_default();
        this.icon = ic_provider.get_icon_for_file(this.file);

        this.icon.image.margin_start += (8 + ((int)level * 20));

        this.label = new Gtk.Label(file.name);
        this.label.xalign = 0;

        this.box.pack_start(this.icon.image, false, true, 10);
        this.box.pack_start(this.label, true, true, 0);

        this.pack_start(eb, false, true, 0);

        this.show_all();

        if (this.file.is_directory)
        {
            this.container = new SortableBox(Gtk.Orientation.VERTICAL, 0);
            this.pack_end(this.container, false, true, 0);
        }
    }

    /*
    ** Static functions
    */

    public static SortableBox? tree_is_sortable_function(void *a)
    {
        var _a = (a as TreeItem);
        return ((_a.is_directory) ? _a.container : null);
    }

    public static int tree_sort_function(void *a, void *b)
    {
        var _a = (a as TreeItem);
        var _b = (b as TreeItem);

        if (_a.is_directory && !_b.is_directory)
            return (-1);
        if (_b.is_directory && !_a.is_directory)
            return (1);

        return (strcmp(_a.file.name, _b.file.name));
    }
}

public class Proton.TreeView : Sortable
{
    public signal void changed(File file);
    public signal void renamed(string old, string _new);
    public signal void monitor_changed(File f, File? of, FileMonitorEvent e);

    public File                         root     { get; protected set; }
    public TreeItem?                    selected { get; protected set; }
    public HashTable<string, TreeItem>  items;

    private FileMonitor[]   monitors = {};
    private Gtk.Popover     popover;
    private Array<string>   to_be_removed = new Array<string>();
    private Mutex           mutex = Mutex();

    public TreeView(File root)
    {
        base(Gtk.Orientation.VERTICAL, 0);

        this.items = new HashTable<string, TreeItem>(str_hash, str_equal);
        this.root = root;
        this.selected = null;

        this.margin_top = 5;

        var b = new Gtk.Builder.from_resource(
            "/com/raggesilver/Proton/layouts/treeview_popover.ui"
        );
        this.popover = b.get_object("menu") as Gtk.Popover;

        this.loading = true; // this is a loadable compopnent

        this.build.begin(this.root, (_, res) => {
            this.build.end(res);
            this.sort.begin((__, _res) => {
                this.sort.end(_res);
                this.loading = false;
            });
        });
    }

    private void select(TreeItem r, bool soft = false)
    {
        if (this.selected != null)
            this.selected.get_style_context().remove_class("selected");

        r.get_style_context().add_class("selected");
        this.selected = r;

        if (!soft)
            this.changed(r.file);
    }

    private void do_sort()
    {
        base.sort(TreeItem.tree_sort_function,
                  TreeItem.tree_is_sortable_function);
    }

    private new async void sort()
    {
        SourceFunc callback = this.sort.callback;

        new Thread<bool>("sort_tree_thread", () => {
            this.do_sort();
            Idle.add((owned)callback);
            return (true);
        });

        yield;
    }

    private void on_monitor_changed(GLib.File _f,
                                    GLib.File? _of,
                                    FileMonitorEvent e)
    {
        var f = new File(_f.get_path());
        var of = (_of == null) ? null : new File(_of.get_path());

        if (e == FileMonitorEvent.CREATED)
        {
            this.t_insert_file.begin(f);
        }
        else if (e == FileMonitorEvent.MOVED_IN)
        {
            this.t_insert_file.begin(f);
            this.renamed(f.path, of.path);
        }
        else if (e == FileMonitorEvent.MOVED_OUT)
        {
            this.remove_file(f);
            this.renamed(f.path, of.path);
        }
        else if (e == FileMonitorEvent.RENAMED)
        {
            // FIXME: This could be optimized by actually just renaming the file
            this.remove_file(f);
            this.t_insert_file.begin(of);
            this.renamed(f.path, of.path);
        }
        else if (e == FileMonitorEvent.DELETED)
        {
            this.remove_file(f);
        }
        this.monitor_changed(f, of, e);
    }

    private async void build(File _root)
    {
        SourceFunc callback = this.build.callback;

        new Thread<bool>("build_tree_thread", () => {
            this.t_do_build(_root, (_, res) => {
                this.t_do_build.end(res);
                Idle.add((owned)callback);
            });
            return (true);
        });

        yield;
    }

    private async void t_do_build(File _root)
    {
        try
        {
            var dir = Dir.open(_root.path);
            string? fname = null;

            var m = _root.file.monitor_directory(
                FileMonitorFlags.WATCH_MOVES
            );

            m.changed.connect(this.on_monitor_changed);
            this.monitors += m;

            while ((fname = dir.read_name()) != null)
            {
                var f = new File(
                    @"$(_root.path)$(Path.DIR_SEPARATOR_S)$fname"
                );

                yield t_insert_file(f, false);
            }
        }
        catch (Error e) { warning(e.message); }
    }

    async void t_item_insert(string key, TreeItem val)
    {
        mutex.lock();
        this.items.insert(key, val);
        mutex.unlock();
    }

    private async void t_insert_file(File f, bool do_sort = true)
    {
        // Prevent double insert
        if (this.items.get(f.path) != null)
            return ;

        if (this.should_be_removed(f.path))
        {
            this.remove_from_to_be_removed(f.path);
            return ;
        }

        // Get path segments starting at project root
        var arr = f.path.replace(this.root.path + "/", "").split("/");
        var r = new TreeItem(f, arr.length - 1);

        r.left_click.connect(() => {
            this.select(r);

            if (r.is_directory)
                r.toggle_expanded();

            return (false);
        });

        r.right_click.connect(() => {
            this.select(r, true);

            this.popover.relative_to = r;
            this.popover.popup();
            return (false);
        });

        r.populate.connect((f) => {
            this.build.begin(r.file, (_, res) => {
                this.build.end(res);
                r.do_sort();
                f();
            });
            return (true);
        });

        var p = f.file.get_parent();

        // Direct child of project root
        if (p != null && p.get_path() == this.root.path)
        {
            this.pack_start(r, false, true, 0);
            yield t_item_insert(f.path, r);

            if (do_sort)
                this.do_sort();
        }
        else if (p != null)
        {
            var r_parent = this.items.get(p.get_path());

            // Parent row (TreeItem) doesn't yet exist
            if (r_parent == null)
            {
                yield t_insert_file(new File(p.get_path()), do_sort);
                r_parent = this.items.get(p.get_path());
            }

            if (r_parent != null)
            {
                yield t_item_insert(f.path, r);
                r_parent.container.pack_start(r, false, true, 0);

                if (do_sort)
                    r_parent.container.sort(TreeItem.tree_sort_function, null);
            }
            // FIXME: This next line is most likely unecessary
            else if (do_sort)
                this.do_sort();
        }
    }

    private long to_be_removed_id = 0;

    private void add_to_be_removed(string file)
    {
        foreach (var _f in this.to_be_removed.data)
            if (_f == file)
                return ;
        this.to_be_removed.append_val(file);

        to_be_removed_id = Timeout.add(10, () => {
            return (this._try_remove());
        });
    }

    private bool _try_remove()
    {
        foreach (var _f in this.to_be_removed.data)
        {
            if (this.items.get(_f) != null)
                this.remove_file(new File(_f));
        }
        if (this.to_be_removed.length > 0)
            to_be_removed_id = Timeout.add(10, () => {
                return (this._try_remove());
            });
        return (false);
    }

    private bool should_be_removed(string file)
    {
        foreach (var _f in this.to_be_removed.data)
            if (_f == file)
                return (true);
        return (false);
    }

    private void remove_from_to_be_removed(string file)
    {
        for (uint i = 0; i < this.to_be_removed.length; i++)
            if (this.to_be_removed.index(i) == file)
            {
                this.to_be_removed.remove_index(i);
                return ;
            }
    }

    private void remove_file(File f)
    {
        string target = f.path;
        TreeItem? r = null;

        if ((r = this.items.get(target)) == null)
        {
            add_to_be_removed(target);
        }
        else
        {
            remove_from_to_be_removed(target);
            this.items.steal(target);

            if (r.container != null)
            {
                var lst = r.container.get_children();
                foreach (var k in lst)
                    remove_file((k as TreeItem).file);
            }

            r.destroy();
        }
    }
}

