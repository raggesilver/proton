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

public class Proton.SortableBox : Gtk.Box
{
    public delegate int PCompareFunction(void *a, void *b);
    public delegate SortableBox? PIsSortableFunction(void *a);

    public SortableBox(Gtk.Orientation orientation, int spacing)
    {
        Object(orientation: orientation,
               spacing: spacing);
    }

    public void sort(PCompareFunction comp,
                     PIsSortableFunction? is_sort,
                     bool do_recursion = true)
    {
        // EventBox > Box > Image + Label
        var lst = new Array<Gtk.Widget>();

        get_children().foreach((k) => { lst.append_val(k); });

        var len = lst.length;

        for (uint i = 0; i < len; i++)
        {
            for (uint j = i; j < len; j++)
                if (comp(lst.index(j), lst.index(i)) < 0)
                {
                    reorder_child(lst.index(j), (int)i);
                    Gtk.Widget tmp = lst.index(i);
                    lst.data[i] = lst.index(j);
                    lst.data[j] = tmp;
                }
        }

        if (is_sort != null && do_recursion)
        {
            for (uint i = 0; i < len; i++)
            {
                var s = is_sort(lst.index(i));
                if (s != null)
                    s.sort(comp, is_sort);
            }
        }
    }
}

public class Proton.TreeItem : Gtk.Box
{
    public signal bool left_click();
    public signal bool right_click();

    public File file { get; protected set; }
    public SortableBox container = null;
    public bool is_directory {
        get {
            return (file.is_directory);
        }
    }

    Gtk.Label label;
    Gtk.Image icon;
    Gtk.Box   box;
    int       level;

    public TreeItem(File _file, int _level = 0)
    {
        Object(orientation: Gtk.Orientation.VERTICAL,
               spacing: 0);

        get_style_context().add_class("treeitem");

        file = _file;
        level = _level;

        build_ui();
    }

    public TreeItem.from_path(string s, int _level = 0)
    {
        this(new File(s), _level);
    }

    public void toggle_expanded()
    {
        if (!is_directory)
            return ;

        bool s = !container.get_visible();

        if (get_icon_name() == "folder-symbolic")
        {
            icon.set_from_icon_name(
                s ? "folder-open-symbolic" : "folder-symbolic",
                Gtk.IconSize.MENU);
        }

        container.set_visible(s);
    }

    public static SortableBox? tree_is_sortable_function(void *_a)
    {
        var a = (_a as TreeItem);
        return ((a.is_directory) ? a.container : null);
    }

    public static int tree_sort_function(void *_a, void *_b)
    {
        var a = (_a as TreeItem);
        var b = (_b as TreeItem);

        if (a.is_directory)
        {
            if (!b.is_directory)
                return (-1);
        }
        if (b.is_directory)
        {
            if (!a.is_directory)
                return (1);
        }

        return (strcmp(a.file.name, b.file.name));
    }

    public void do_sort()
    {
        container.sort(tree_sort_function, tree_is_sortable_function);
    }

    void build_ui()
    {
        var eb = new Gtk.EventBox();

        box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        eb.button_release_event.connect((e) => {
            if (e.button == 1)
                return (left_click());
            else if (e.button == 3)
                return (right_click());
            return (false);
        });
        eb.add(box);

        box.set_size_request(-1, 25);

        icon = new Gtk.Image.from_icon_name(
            get_icon_name(), Gtk.IconSize.MENU);
        icon.margin_start += 5 + (level * 16);

        label = new Gtk.Label(file.name);
        label.xalign = 0;

        box.pack_start(icon, false, true, 10);
        box.pack_start(label, false, true, 0);

        pack_start(eb, false, true, 0);
        show_all();

        if (file.is_directory)
        {
            container = new SortableBox(Gtk.Orientation.VERTICAL, 0);
            pack_end(container, false, true, 0);
        }
    }

    string get_icon_name()
    {
        Icon ic = file.icon;

        if (ic == null)
            return ("text-x-generic");

        string[] arr = ic.to_string().split(" ");

        return (arr[arr.length - 1]);
    }
}

public class Proton.TreeView : SortableBox
{
    public signal void changed(File file);
    public signal void renamed(string old, string _new);

    public File root { get; protected set; }
    public HashTable<string, TreeItem> items { get; protected set; }
    public TreeItem? selected { get; protected set; }

    FileMonitor[] monitors = {};
    Gtk.Popover popover;

    public TreeView(File root)
    {
        Object(orientation: Gtk.Orientation.VERTICAL,
               spacing: 0,
               items: new HashTable<string, TreeItem>(str_hash, str_equal),
               root: root,
               selected: null);

        var b = new Gtk.Builder.from_resource(
            "/com/raggesilver/Proton/layouts/treeview_popover.ui");
        popover = b.get_object("menu") as Gtk.Popover;

        // FIXME this crashes randomly "munmap_chunk(): invalid pointer"
        // new Thread<bool>("load_tree_view", () => {
        //     build(this.root);
        //     return (true);
        // });
        build(this.root);
        show();
    }

    void build(File _root)
    {
        try
        {
            var dir = Dir.open(_root.path);
            string? fname = null;

            // Attach monitor
            try
            {
                var m = _root.file.monitor_directory(
                            FileMonitorFlags.WATCH_MOVES);

                m.changed.connect(on_monitor_changed);
                monitors += m;
            }
            catch
            {
                warning("Could not create monitor for %s\n", _root.path);
            }

            while ((fname = dir.read_name()) != null)
            {
                var f = new File(@"$(_root.path)$(Path.DIR_SEPARATOR_S)$fname");

                insert_file(f, false);

                if (f.is_directory)
                    build(f);
            }
        }
        catch (Error e) { warning(e.message); }

        if (_root.path == this.root.path)
            do_sort();
    }

    void select(TreeItem r, bool soft = false)
    {
        if (selected != null)
            selected.get_style_context().remove_class("selected");

        r.get_style_context().add_class("selected");
        selected = r;

        if (!soft)
            changed(r.file);
    }

    void do_sort()
    {
        sort(TreeItem.tree_sort_function, TreeItem.tree_is_sortable_function);
    }

    void on_monitor_changed(GLib.File _f, GLib.File? _of, FileMonitorEvent e)
    {
        var f = new File(_f.get_path());
        var of = (_of == null) ? null : new File(_of.get_path());

        if (e == FileMonitorEvent.CREATED)
            insert_file(f);
        else if (e == FileMonitorEvent.MOVED_OUT)
            remove_file(f);
        else if (e == FileMonitorEvent.MOVED_IN)
        {
            insert_file(f);

            renamed(of.path, f.path);

            if (f.is_directory)
                build(f);
        }
        else if (e == FileMonitorEvent.MOVED_OUT)
        {
            remove_file(f);
            renamed(f.path, of.path);
        }
        else if (e == FileMonitorEvent.RENAMED)
        {
            remove_file(f);
            insert_file(of);
            renamed(f.path, of.path);
        }
        else if (e == FileMonitorEvent.DELETED)
            remove_file(f);
    }

    void insert_file(File f, bool do_sort = true)
    {
        if (items.get(f.path) != null)
            return ;

        var r = new TreeItem(f,
            f.path.replace(@"$(this.root.path)/", "").split("/").length - 1);

        r.left_click.connect(() => {
            select(r);

            if (r.is_directory)
                r.toggle_expanded();

            return (false);
        });

        r.right_click.connect(() => {
            select(r, true);

            popover.relative_to = r;
            popover.popup();
            return (false);
        });

        var p = f.file.get_parent();
        if (p != null && p.get_path() == root.path)
        {
            pack_start(r, false, true, 0);
            items.insert(f.path, r);
            if (do_sort)
                sort(TreeItem.tree_sort_function, null);
        }
        else if (p != null)
        {
            var parent = items.get(p.get_path());

            if (parent == null)
            {
                insert_file(new File(p.get_path()), do_sort);
                parent = items.get(p.get_path());
            }

            if (parent != null)
            {
                items.insert(f.path, r);
                parent.container.pack_start(r, false, true, 0);
                parent.container.queue_resize();
                if (do_sort)
                    parent.container.sort(TreeItem.tree_sort_function, null);
            }
        }
    }

    void remove_file(File f)
    {
        string target = f.file.get_path();
        var r = items.get(target);
        if (r == null)
            return ;

        if (r.container != null)
        {
            var lst = r.container.get_children();
            lst.foreach((k) => {
                remove_file((k as TreeItem).file);
            });
        }

        items.remove(target);
        r.destroy();
    }
}

