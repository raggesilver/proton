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

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/window.ui")]
public class Proton.Window : Gtk.ApplicationWindow
{
    [GtkChild] Gtk.Box side_panel_box;
    [GtkChild] Gtk.Box title_box;
    [GtkChild] Gtk.Button preferences_button;
    [GtkChild] Gtk.Button save_button;
    [GtkChild] Gtk.ScrolledWindow tree_view_scrolled;
    [GtkChild] Gtk.Stack side_panel_stack;
    [GtkChild] Gtk.ToggleButton toggle_bottom_panel_button;
    [GtkChild] Gtk.ToggleButton toggle_left_panel_button;
    [GtkChild] Gtk.StackSwitcher side_panel_stack_switcher;

    [GtkChild] public Gtk.Box left_hb_box;
    [GtkChild] public Gtk.Box right_hb_box;
    [GtkChild] public Gtk.HeaderBar header_bar;
    [GtkChild] public Gtk.Overlay overlay;

    //
    // Signals

    public signal bool on_accel(string accel);

    //
    // Members

    public BottomPanel         bottom_panel    { get; protected set; }
    public CommandPalette      command_palette { get; private set; }
    public Dazzle.DockBin      dockbin         { get; private set; }
    public Dazzle.DockRevealer bottom_edge     { get; private set; }
    public Dazzle.DockRevealer left_edge       { get; private set; }
    public EditorManager       manager         { get; private set; }
    public File                root            { get; protected set; }
    public Gtk.AccelGroup      accel_group     { get; private set; }
    public IdeGrid             grid            { get; protected set; }
    public StatusBox           status_box      { get; private set; }
    public TerminalTab         terminal_tab    { get; protected set; }
    public TreeView            tree_view       { get; private set; }

    private PreferencesWindow  preferences_window = null;
    private PluginManager      pm;

    public Window(Gtk.Application app, File root)
    {
        Object(application: app, root: root);

        Gtk.IconTheme.get_default().append_search_path(
            @"$(Constants.DATADIR)/proton/icons");

        // Initialize stuff
        this.accel_group     = new Gtk.AccelGroup();
        this.bottom_panel    = new BottomPanel(this);
        this.command_palette = new CommandPalette(this);
        this.dockbin         = new Dazzle.DockBin();
        this.manager         = new EditorManager(this);
        this.pm              = new PluginManager(this);
        this.tree_view       = new TreeView(this);
        this.status_box      = new StatusBox(this);
        this.grid            = new IdeGrid(this);
        this.grid.show();

        this.left_edge   = this.dockbin.get_left_edge() as Dazzle.DockRevealer;
        this.bottom_edge =
            this.dockbin.get_bottom_edge() as Dazzle.DockRevealer;

        this.left_edge.transition_type =
            Dazzle.DockRevealerTransitionType.SLIDE_RIGHT;

        this.bottom_edge.transition_type =
            Dazzle.DockRevealerTransitionType.SLIDE_UP;

        this.left_edge.transition_duration   = 250;
        this.bottom_edge.transition_duration = 250;

        //
        // Connections

        this.tree_view.changed.connect((f) => {
            if (f.is_directory || !f.is_valid_textfile)
                return ;

            this.grid.open_file(f);
        });

        this.tree_view.renamed.connect((o, n) => {
            this.manager.renamed(o, n);
        });

        this.manager.changed.connect((ed) => {
            this.save_button.set_sensitive(false);

            if (ed != null && ed.file != null)
                this.save_button.set_sensitive(true);
        });

        this.manager.modified.connect((mod) => {
            TreeItem? item = this.tree_view.items.get(
                                this.manager.current_editor.file.path);

            if (item != null)
                item.set_modified(mod);
        });

        // Load previous state from settings
        this.toggle_left_panel_button.set_active(settings.left_panel_visible);
        this.toggle_left_panel_button.clicked.connect(() => {
            if (this.toggle_left_panel_button.active !=
                settings.left_panel_visible)
            {
                settings.left_panel_visible = !settings.left_panel_visible;
            }
        });

        settings.notify["left-panel-visible"].connect(() => {
            this.left_edge.reveal_child = settings.left_panel_visible;

            if (this.toggle_left_panel_button.active !=
                settings.left_panel_visible)
            {
                this.toggle_left_panel_button
                    .set_active(settings.left_panel_visible);
            }
        });

        // Load previous state from settings
        this.toggle_bottom_panel_button
            .set_active(settings.bottom_panel_visible);
        this.toggle_bottom_panel_button.clicked.connect(() => {
            if (this.toggle_bottom_panel_button.active
                    != settings.bottom_panel_visible)
            {
                settings.bottom_panel_visible = !settings.bottom_panel_visible;
            }
        });

        settings.notify["bottom-panel-visible"].connect(() => {
            this.bottom_edge.reveal_child = settings.bottom_panel_visible;

            if (this.toggle_bottom_panel_button.active
                    != settings.bottom_panel_visible)
            {
                this.toggle_bottom_panel_button
                    .set_active(settings.bottom_panel_visible);
            }
        });

        this.add_accel_group(this.accel_group);
        this.manager.connect_accels(this.accel_group);

        // TODO: maybe mark this.save_button_clicked as GtkCallback
        this.save_button.clicked.connect(this.save_button_clicked);

        var a = new SimpleAction("about", null);
        a.activate.connect(on_about);
        this.add_action(a);

        a = new SimpleAction("new_project", null);
        a.activate.connect(() => {
            var w = new OpenWindow.open_at(this.application,
                                           "new_project_page");
            w.show();
        });
        this.add_action(a);

        a = new SimpleAction("clone_project", null);
        a.activate.connect(() => {
            var w = new OpenWindow.open_at(this.application,
                                           "clone_page");
            w.show();
        });
        this.add_action(a);

        a = new SimpleAction("open_project", null);
        a.activate.connect(() => {
            var w = new OpenWindow(this.application);
            w.show();
        });
        this.add_action(a);

        a = new SimpleAction("preferences", null);
        a.activate.connect(this.on_preferences);
        this.add_action(a);

        this.build_ui();
        this.pm.load.begin();
        this.delete_event.connect(on_delete);
        this.apply_settings();
        this.bind_accels();
    }

    private void on_about()
    {
        new AboutWindow(this).run();
    }

    private void bind_accels()
    {
        accel_group.connect(Gdk.Key.grave,
                            Gdk.ModifierType.CONTROL_MASK,
                            0,
                            toggle_bottom_panel);

        accel_group.connect(Gdk.Key.comma,
                            Gdk.ModifierType.CONTROL_MASK,
                            0,
                            () => {
            this.on_preferences();
            return (false);
        });

        accel_group.connect(Gdk.Key.b,
                            Gdk.ModifierType.CONTROL_MASK,
                            0,
                            toggle_left_panel);

        key_press_event.connect((e) => {
            string? k = null;
            if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 &&
                (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 &&
                (k = Gdk.keyval_name(e.keyval)) != null)
            {
                return (on_accel(@"<ctrl><shift>$k"));
            }
            return (false);
        });
    }

    public bool toggle_left_panel()
    {
        settings.left_panel_visible = !settings.left_panel_visible;
        return false;
    }

    public bool toggle_bottom_panel()
    {
        settings.bottom_panel_visible = !settings.bottom_panel_visible;
        return false;
    }

    private void save_button_clicked ()
    {
        manager.save();
    }

    private void build_ui()
    {
        this.side_panel_stack_switcher.set_homogeneous(true);

        if (settings.width > 0 && settings.height > 0)
            this.resize(settings.width, settings.height);

        if (settings.pos_x > 0 && settings.pos_y > 0)
            this.move(settings.pos_x, settings.pos_y);

        title_box.set_center_widget(this.status_box);

        this.tree_view_scrolled.add(this.tree_view);

        side_panel_stack.set_visible_child_name("treeview");

        this.left_edge.add(this.side_panel_box);
        this.side_panel_box.set_vexpand(true);

        this.dockbin.add(grid);

        this.bottom_edge.add(this.bottom_panel);
        this.bottom_panel.set_hexpand(true);

        terminal_tab = new TerminalTab(this);
        bottom_panel.add_tab(terminal_tab);

        left_edge.reveal_child = settings.left_panel_visible;
        bottom_edge.reveal_child = settings.bottom_panel_visible;

        bottom_edge.set_position(settings.bottom_panel_height);
        left_edge.set_position(settings.left_panel_width);

        this.overlay.add(this.dockbin);
        this.dockbin.show();
    }

    private bool can_close()
    {
        int ct = 0;

        foreach (var ed in manager.editors.get_values())
        {
            if (ed.is_modified)
                ct++;
        }

        if (ct > 0)
        {
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
            else
            {
                save_all_and_close.begin();
                return false;
            }
        }
        return true;
    }

    private async void save_all_and_close()
    {
        foreach (var ed in manager.editors.get_values())
        {
            if (ed.is_modified && !(yield ed.save()))
            {
                warning("File %s was not saved\n", ed.file.name);
                return ;
            }
        }
        this.destroy();
    }

    private bool on_delete()
    {
        int width, height;
        this.get_size(out width, out height);
        settings.width = width;
        settings.height = height;

        int pos_x, pos_y;
        get_position(out pos_x, out pos_y);
        settings.pos_x = pos_x;
        settings.pos_y = pos_y;

        int bph = bottom_edge.get_position();
        settings.bottom_panel_height = bph;

        settings.left_panel_width = left_edge.get_position();

        if (!can_close())
            return true;

        return false;
    }

    private void on_preferences()
    {
        if (this.preferences_window == null)
        {
            this.preferences_window = new PreferencesWindow(this);
            this.preferences_window.delete_event.connect(() => {
                this.preferences_window = null;
                return false;
            });
        }
        this.preferences_window.show();
    }

    public void apply_settings()
    {
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_resource(
            "/com/raggesilver/Proton/resources/style.css");

        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        Gtk.Settings.get_default()
                .gtk_application_prefer_dark_theme = settings.dark_mode;

        settings.notify["dark-mode"].connect(() => {
            Gtk.Settings.get_default()
                .gtk_application_prefer_dark_theme = settings.dark_mode;
        });

        if (settings.transparency)
            this.get_style_context().add_class("transparent");

        settings.notify["transparency"].connect(() => {
            if (settings.transparency)
                this.get_style_context().add_class("transparent");
            else
                this.get_style_context().remove_class("transparent");
        });
    }
}
