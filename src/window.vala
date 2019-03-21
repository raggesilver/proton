/* window.vala
 *
 * Copyright 2019 Paulo Queiroz
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

Gtk.ScrolledWindow wrap_scroller(Gtk.Widget w) {
    var s = new Gtk.ScrolledWindow (null, null);
    s.add (w);
    w.show ();
    s.show ();
    return (s);
}

//  static TypeModule module = null;

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/window.ui")]
public class Proton.Window : Gtk.ApplicationWindow {

    // [GtkChild]
    // Gtk.Box side_panel_box;

    [GtkChild]
    Gtk.Stack side_panel_stack;

    [GtkChild]
    Gtk.Stack bottom_panel_stack;

    [GtkChild]
    Gtk.Stack bottom_panel_aux_stack;

    [GtkChild]
    Gtk.Stack editor_stack;

    [GtkChild]
    Gtk.Button save_button;

    [GtkChild]
    Gtk.Button play_button;

    [GtkChild]
    Gtk.Box bottom_box;

    [GtkChild]
    Gtk.Box side_panel_box;

    [GtkChild]
    Gtk.Paned editor_paned;

    [GtkChild]
    Gtk.Paned outer_paned;

    private Proton.EditorManager manager;
    private TreeView tree_view;
    public Gtk.AccelGroup accel_group { get; private set; }
    // private PluginManager pm;

    public Window (Gtk.Application app) {

        Object (application: app);

        // Initialize stuff
        accel_group = new Gtk.AccelGroup();
        manager = EditorManager.get_instance();
        tree_view = new TreeView(root);

        add_accel_group(accel_group);
        manager.connect_accels(accel_group);

        if (settings.width > 0 && settings.height > 0)
            resize(settings.width, settings.height);

        if (settings.pos_x > 0 && settings.pos_y > 0)
            move(settings.pos_x, settings.pos_y);

        build_ui();

        try {
            PluginLoader loader = new PluginLoader();
            PluginIface plugin = loader.load(Constants.PLUGINDIR + "/editorconfig/libeditorconfig");
            plugin.activate();
        } catch (PluginError e) {
            print("Error: %s\n", e.message);
        }

        // Connect events
        play_button.set_sensitive(Proton.Core.get_instance().can_play);
        play_button.clicked.connect(play_button_clicked);

        Proton.Core.get_instance().play_changed.connect((c) => {
            set_can_play(c);
        });

        Proton.Core.get_instance().monitor_changed.connect((f, of, e) => {
            if (e == GLib.FileMonitorEvent.ATTRIBUTE_CHANGED ||
                e == GLib.FileMonitorEvent.CHANGED ||
                e == GLib.FileMonitorEvent.CHANGES_DONE_HINT)
                return ;
            stdout.printf("PASSED %s\n", e.to_string());
            tree_view.refill();
        });

        manager.changed.connect(current_editor_changed);
        manager.modified.connect((mod) => {
            set_title("Proton - " + manager.current_editor.file.name +
                ((mod) ? " •" : ""));
        });

        save_button.clicked.connect(save_button_clicked);
        tree_view.selected.connect(tree_view_selected);
        delete_event.connect(on_delete);

        apply_settings();

        bind_accels();
    }

    private void bind_accels() {
        accel_group.connect(Gdk.Key.grave,
                            Gdk.ModifierType.CONTROL_MASK,
                            0,
                            toggle_bottom_panel);

        accel_group.connect(Gdk.Key.b,
                            Gdk.ModifierType.CONTROL_MASK,
                            0,
                            toggle_left_panel);
        accel_group.connect(Gdk.Key.F5,
                            0,
                            0,
                            do_build);
    }

    public bool do_build() {
        play_button_clicked();
        return false;
    }

    public bool toggle_left_panel() {
        settings.left_panel_visible = !settings.left_panel_visible;
        side_panel_box.set_visible(settings.left_panel_visible);
        return false;
    }

    public bool toggle_bottom_panel() {
        settings.bottom_panel_visible = !settings.bottom_panel_visible;
        bottom_box.set_visible(settings.bottom_panel_visible);
        return false;
    }

    private void set_can_play(bool c) {
        play_button.set_sensitive(c);
    }

    private void play_button_clicked() {
        Terminal? a = null;
        if ((a = bottom_panel_stack.get_child_by_name("make-term") as Terminal)
            == null) {
            bottom_panel_stack.add_titled(new Terminal(this),
                                          "make-term",
                                          "Make");
        }
        a = (bottom_panel_stack.get_child_by_name("make-term") as Terminal);
        bottom_panel_stack.set_visible_child_name("make-term");
        a.feed_child("reset && make\n".to_utf8());
    }

    private void current_editor_changed(Editor? ed) {
        save_button.set_sensitive(false);
        if (ed != null && ed.file != null)
            save_button.set_sensitive(true);
    }

    private void save_button_clicked () {
        manager.save();
    }

    private void build_ui() {
        side_panel_stack.add_titled(wrap_scroller(tree_view),
                                    "treeview",
                                    "Project");

        side_panel_stack.set_visible_child_name("treeview");

        bottom_panel_stack.add_titled(new Terminal(this),
                                      "terminal",
                                      "Terminal");

        bottom_panel_stack.set_visible_child_name("terminal");

        bottom_panel_stack.notify.connect((spec) => {
            if (spec.name != "visible-child-name")
                return ;

            stdout.printf("CHANGE VIEW TO %s\n",
                bottom_panel_stack.visible_child_name);

            Gtk.Widget? child = bottom_panel_aux_stack.get_child_by_name(
                bottom_panel_stack.visible_child_name);

            if (child != null)
                bottom_panel_aux_stack.set_visible_child(child);
            else
                bottom_panel_aux_stack.set_visible_child_name("empty");
        });

        side_panel_box.set_visible(settings.left_panel_visible);
        bottom_box.set_visible(settings.bottom_panel_visible);

        bottom_box.set_size_request(-1, settings.bottom_panel_height);
        outer_paned.set_position(settings.left_panel_width);
    }

    private void tree_view_selected(File f) {
        if (f.is_directory)
            return ;

        var editor = Proton.EditorManager.get_instance().open(f);

        if (editor_stack.get_child_by_name("editor" + f.path) == null) {
            editor_stack.add_titled(editor.sview, @"editor$(f.path)", "Editor");
        }

        editor_stack.set_visible_child_name("editor" + f.path);
        editor.sview.grab_focus();
    }

    private bool can_close() {
        int ct = 0;

        foreach (var ed in manager.editors.get_values()) {
            if (ed.is_modified)
                ct++;
        }

        if (ct > 0) {

            var md = new Gtk.MessageDialog(
                this,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.WARNING,
                Gtk.ButtonsType.CANCEL,
                "Are you sure you want to quit?");

            md.format_secondary_text(
                @"There are $ct unsaved file$((ct > 1) ? "s" : "").");
            md.add_button("Discard", Gtk.ResponseType.YES);
            md.add_button("Save all", Gtk.ResponseType.OK);

            var res = md.run();
            md.destroy();

            if (res == Gtk.ResponseType.CANCEL)
                return false;
            else if (res == Gtk.ResponseType.YES)
                return true;
            else {
                save_all_and_close.begin();
                return false;
            }
        }
        return true;
    }

    private async void save_all_and_close() {
        foreach (var ed in manager.editors.get_values()) {
            if (ed.is_modified) {
                if (!(yield ed.save())) {
                    stdout.printf("File %s was not saved\n", ed.file.name);
                    return ;
                }
            }
        }
        this.destroy();
    }

    private bool on_delete() {

        int width, height;
        this.get_size(out width, out height);
        settings.width = width;
        settings.height = height;

        int pos_x, pos_y;
        get_position(out pos_x, out pos_y);
        settings.pos_x = pos_x;
        settings.pos_y = pos_y;

        int bph = editor_paned.get_allocated_height()
            - editor_paned.get_position();
        settings.bottom_panel_height = bph;

        settings.left_panel_width = outer_paned.get_position();

        if (!can_close())
            return true;

        return false;
    }

    public void apply_settings() {
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_resource(
            "/com/raggesilver/Proton/resources/style.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}
