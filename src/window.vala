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

    [GtkChild]
    public Gtk.HeaderBar header_bar;

    [GtkChild]
    public Gtk.Box left_hb_box;

    [GtkChild]
    public Gtk.Box right_hb_box;

    [GtkChild]
    Gtk.Stack side_panel_stack;

    [GtkChild]
    Gtk.Stack bottom_panel_stack;

    [GtkChild]
    Gtk.Stack bottom_panel_aux_stack;

    [GtkChild]
    Gtk.Stack editor_stack;

    [GtkChild]
    Gtk.Button preferences_button;

    [GtkChild]
    Gtk.Button save_button;

    [GtkChild]
    Gtk.ToggleButton toggle_left_panel_button;

    [GtkChild]
    Gtk.ToggleButton toggle_bottom_panel_button;

    [GtkChild]
    Gtk.Box bottom_panel_box;

    [GtkChild]
    Gtk.Box title_box;

    [GtkChild]
    Gtk.Box side_panel_box;

    [GtkChild]
    Gtk.Paned editor_paned;

    [GtkChild]
    Gtk.Paned outer_paned;

    [GtkChild]
    public Gtk.Overlay overlay;

    EditorManager     manager;
    TreeView          tree_view;
    PreferencesWindow preferences_window = null;

    public Gtk.AccelGroup accel_group      { get; private set; }
    public CommandPalette command_palette  { get; private set; }
    public File           root             { get; protected set; }

    public Window(Gtk.Application app, File root) {

        Object(application: app,
               root: root);

        Gtk.IconTheme.get_default().append_search_path(
            @"$(Constants.DATADIR)/proton/icons");

        // Initialize stuff
        accel_group = new Gtk.AccelGroup();
        command_palette = new CommandPalette(this);
        tree_view = new TreeView(root);
        manager = new EditorManager(this);

        var status_box = new StatusBox(this);
        title_box.set_center_widget(status_box);

        tree_view.changed.connect((f) => {
            if (f.is_directory || !f.is_valid_textfile)
                return ;

            manager.open(f);
        });

        tree_view.renamed.connect((o, n) => {
            manager.renamed(o, n);
        });

        manager.created.connect((ed) => {
            editor_stack.add_named(ed.sview, ed.file.path);
        });

        manager.changed.connect((ed) => {
            save_button.set_sensitive(false);

            if (ed != null && ed.file != null) {
                save_button.set_sensitive(true);
                editor_stack.set_visible_child(ed.sview);
                status_box.set_filename(manager.current_editor.file.name +
                    ((manager.current_editor.is_modified) ? " •" : ""));
            }
        });

        manager.modified.connect((mod) => {
            status_box.set_filename(manager.current_editor.file.name +
                ((mod) ? " •" : ""));
            tree_view.items.get(manager.current_editor.file.path)
                .set_modified(mod);
        });

        toggle_left_panel_button.set_active(settings.left_panel_visible);
        toggle_left_panel_button.clicked.connect(() => {
            if (toggle_left_panel_button.active != settings.left_panel_visible)
            {
                settings.left_panel_visible = !settings.left_panel_visible;
            }
        });

        settings.notify["left-panel-visible"].connect(() => {
            side_panel_box.set_visible(settings.left_panel_visible);

            if (toggle_left_panel_button.active != settings.left_panel_visible)
            {
                toggle_left_panel_button
                    .set_active(settings.left_panel_visible);
            }
        });

        toggle_bottom_panel_button.set_active(settings.bottom_panel_visible);
        toggle_bottom_panel_button.clicked.connect(() => {
            if (toggle_bottom_panel_button.active
                    != settings.bottom_panel_visible)
            {
                settings.bottom_panel_visible = !settings.bottom_panel_visible;
            }
        });

        settings.notify["bottom-panel-visible"].connect(() => {
            bottom_panel_box.set_visible(settings.bottom_panel_visible);

            if (toggle_bottom_panel_button.active
                    != settings.bottom_panel_visible)
            {
                toggle_bottom_panel_button
                    .set_active(settings.bottom_panel_visible);
            }
        });

        add_accel_group(accel_group);
        manager.connect_accels(accel_group);

        if (settings.width > 0 && settings.height > 0)
            resize(settings.width, settings.height);

        if (settings.pos_x > 0 && settings.pos_y > 0)
            move(settings.pos_x, settings.pos_y);

        build_ui();

        PluginLoader loader = new PluginLoader(this);
        PluginIface[] _iplugins = {};
        string[] _plugins = {"editorconfig", "runner"};
        manager.changed.connect((e) => {
            loader.editor_changed(e);
        });

        foreach (var p in _plugins) {
            try {
                PluginIface plugin = loader.load(
                    @"$(Constants.PLUGINDIR)/$p/lib$p");
                plugin.activate();
                _iplugins += plugin;
            } catch (PluginError e) {
                warning("Error: %s\n", e.message);
            }
        }

        save_button.clicked.connect(save_button_clicked);

        preferences_button.clicked.connect(() => {
            if (preferences_window == null) {
                preferences_window = new PreferencesWindow(this.application);
                preferences_window.delete_event.connect(() => {
                    preferences_window = null;
                    return false;
                });
            }
            preferences_window.show();
        });

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
    }

    public bool toggle_left_panel() {
        settings.left_panel_visible = !settings.left_panel_visible;
        return false;
    }

    public bool toggle_bottom_panel() {
        settings.bottom_panel_visible = !settings.bottom_panel_visible;
        return false;
    }

    private void save_button_clicked () {
        manager.save();
    }

    private void build_ui() {
        side_panel_stack.add_titled(wrap_scroller(tree_view),
                                    "treeview",
                                    "Project");

        side_panel_stack.set_visible_child_name("treeview");

        bottom_panel_stack.add_titled(wrap_scroller(new Terminal(this)),
                                      "terminal",
                                      "TERMINAL");

        bottom_panel_stack.notify.connect((spec) => {
            if (spec.name != "visible-child-name")
                return ;

            Gtk.Widget? child = bottom_panel_aux_stack.get_child_by_name(
                bottom_panel_stack.visible_child_name);

            if (child != null)
                bottom_panel_aux_stack.set_visible_child(child);
            else
                bottom_panel_aux_stack.set_visible_child_name("empty");
        });

        bottom_panel_stack.set_visible_child_name("terminal");

        side_panel_box.set_visible(settings.left_panel_visible);
        bottom_panel_box.set_visible(settings.bottom_panel_visible);

        editor_paned.set_position(settings.bottom_panel_height);
        outer_paned.set_position(settings.left_panel_width);
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
                    warning("File %s was not saved\n", ed.file.name);
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

        int bph = editor_paned.get_position();
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

        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}

