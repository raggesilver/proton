/* open_window.vala
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
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
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

internal class Proton.RC : Ggit.RemoteCallbacks {}

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/open_window.ui")]
public class Proton.OpenWindow : Gtk.ApplicationWindow
{
    [GtkChild] Gtk.Box recent_box;
    [GtkChild] Gtk.Box recent_vbox;
    [GtkChild] Gtk.Button back_button;
    [GtkChild] Gtk.Button clone_button;
    [GtkChild] Gtk.Button clone_project_button;
    [GtkChild] Gtk.Button new_project_button;
    [GtkChild] Gtk.Button np_create_button;
    [GtkChild] Gtk.Button open_other_button;
    [GtkChild] Gtk.ComboBox np_language_combo;
    [GtkChild] Gtk.Entry clone_repo_entry;
    [GtkChild] Gtk.Entry np_name_entry;
    [GtkChild] Gtk.FileChooserButton clone_location_chooser;
    [GtkChild] Gtk.FileChooserButton np_file_chooser_button;
    [GtkChild] Gtk.Label no_recent_label;
    [GtkChild] Gtk.Label np_error_label;
    [GtkChild] Gtk.Label repo_label;
    [GtkChild] Gtk.Label version_label;
    [GtkChild] Gtk.ListStore np_language_list_store;
    [GtkChild] Gtk.ScrolledWindow scroll;
    [GtkChild] Gtk.Stack stack;
    [GtkChild] Gtk.Switch np_git_switch;
    [GtkChild] Gtk.TextView git_text_view;

    File?   repo_file = null;
    string  clone_url = "";
    string? repo_name = null;

    public OpenWindow(Gtk.Application app)
    {
        Object(application: app);

        this.build_ui();
        this.load_templates();
        this.update_ui();
        this.get_recent();
    }

    public OpenWindow.open_at(Gtk.Application app, string page)
    {
        this(app);
        this.on_change_page(page);
    }

    private void build_ui()
    {
        string projects_path = Environment.get_home_dir() + "/Projects";

        // Set new project file chooser to ~/Projects/ if it exists
        if (FileUtils.test(projects_path, FileTest.IS_DIR))
            np_file_chooser_button.set_filename(projects_path);

        // Connect signals
        this.np_create_button.clicked.connect(this.on_create_project);
        this.clone_button.clicked.connect(this.on_clone_button_pressed);
        this.open_other_button.clicked.connect(this.on_open_other);

        this.clone_project_button.clicked.connect(() => {
            this.on_change_page("clone_page");
        });

        this.back_button.clicked.connect(() => {
            this.on_change_page("welcome_page");
        });

        this.new_project_button.clicked.connect(() => {
            this.on_change_page("new_project_page");
        });
    }

    private void update_ui()
    {
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_resource(
            "/com/raggesilver/Proton/resources/style.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        this.version_label.set_text(@"Version $(Constants.VERSION)");

        var s = Gtk.Settings.get_default();
        s.gtk_application_prefer_dark_theme = settings.dark_mode;
    }

    // Control back_button visibility, stack page and headerbar class
    private void on_change_page(string page)
    {
        switch (page)
        {
            case "clone_page":
                this.get_style_context().remove_class("open-window");
                break;
            default:
                this.get_style_context().add_class("open-window");
                break;
        }
        this.back_button.set_visible(page != "welcome_page");
        this.stack.set_visible_child_name(page);
    }

    // Open project from folder chooser dialog
    private void on_open_other()
    {
        Gtk.FileChooserDialog d;
        int res;

        d = new Gtk.FileChooserDialog("Project folder", this,
                                      Gtk.FileChooserAction.SELECT_FOLDER,
                                      "Cancel", Gtk.ResponseType.CANCEL,
                                      "_Open", Gtk.ResponseType.OK,
                                      null);

        res = d.run();
        d.destroy();
        if (res != Gtk.ResponseType.OK)
            return ;
        this.safe_spawn_and_close(this.application, new File(d.get_filename()));
    }

    // Create and return new recent project button
    private Gtk.Button new_recent_row(File f)
    {
        var r = new Gtk.Button();
        var b = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);

        b.margin_start = 10;

        var lbl = new Gtk.Label("");
        lbl.set_xalign(0);
        lbl.set_halign(Gtk.Align.START);
        lbl.set_markup(@"<b>$(f.name)</b>");
        lbl.set_size_request(-1, 48);

        b.pack_start(lbl, false, true, 0);

        lbl = new Gtk.Label("");
        lbl.set_xalign(0);
        lbl.set_halign(Gtk.Align.START);
        lbl.set_ellipsize(Pango.EllipsizeMode.START);
        lbl.set_sensitive(false);
        lbl.set_markup(@"<i>$(f.path)</i>");

        lbl.set_tooltip_text(f.path);
        b.pack_start(lbl, true, true, 0);

        r.clicked.connect(() => {
            this.safe_spawn_and_close(this.application, f);
        });

        r.add(b);
        r.show_all();
        r.set_relief(Gtk.ReliefStyle.NONE);

        return (r);
    }

    // Get recent projects
    private void get_recent()
    {
        string[] recent = {};
        bool has_recent = false;

        foreach (string s in settings.recent_projects)
        {
            if (FileUtils.test(s, FileTest.IS_DIR))
            {
                recent += s;
                has_recent = true;
                this.recent_vbox.pack_start(this.new_recent_row(new File(s)),
                                            false, true, 0);
            }
        }

        if (has_recent)
        {
            this.no_recent_label.hide();
            this.recent_box.show();
        }

        // Update recent to remove previous projects that don't exist anymore
        settings.recent_projects = recent;
    }

    void on_clone_button_pressed()
    {
        try
        {
            clone_repo_entry.set_sensitive(false);
            clone_button.set_sensitive(false);
            git_text_view.show();
            var c = new Cloner(clone_url, repo_file);

            var buf = git_text_view.get_buffer();
            buf.set_text("", -1);

            c.callbacks.percentage.connect((p) => {
                clone_repo_entry.set_progress_fraction(p / 100);
            });

            c.callbacks.message.connect((text) => {
                debug(text);
                Idle.add(() => {
                    buf.insert_at_cursor(text, text.length);
                scroll.get_vadjustment().value = scroll.get_vadjustment().upper;
                return (false);
                });
            });

            c.complete.connect((res) => {
                if (res)
                {
                    this.safe_spawn_and_close(this.application,
                                              new File(repo_file.path));
                }
                else
                {
                    clone_repo_entry.set_sensitive(true);
                    clone_button.set_sensitive(true);
                    clone_repo_entry.set_progress_fraction(0);
                }
            });

            c.clone();
        }
        catch(Error e)
        {
            warning(e.message);
            clone_repo_entry.set_sensitive(true);
            clone_button.set_sensitive(true);
            clone_repo_entry.set_progress_fraction(0);
        }
    }

    [GtkCallback]
    void on_repo_url_changed()
    {
        clone_url = clone_repo_entry.get_text();

        clone_repo_entry.get_style_context().remove_class("error");

        if (!Cloner.is_valid_url(clone_url))
        {
            clone_repo_entry.get_style_context().add_class("error");
            clone_button.set_sensitive(false);
            return ;
        }

        var i = clone_url.last_index_of("/");
        var s = @"/$(clone_url.offset(i+1))";
        s = s.substring(0, s.length - 4);
        repo_name = repo_label.label = s;

        clone_button.set_sensitive(get_valid_repo());
    }

    bool get_valid_repo()
    {
        if (null == clone_location_chooser.get_file())
            return (false);

        var p = clone_location_chooser.get_file().get_path();

        if (p == null)
            return (false);

        repo_file = new File(p + repo_name);
        return (Cloner.is_valid_target(repo_file));
    }

    void on_create_project()
    {
        string? lang = null;
        string? path = null;

        if (!validate_np(out path, out lang))
            return;

        if (lang != null)
        {
            string tp = Constants.DATADIR + "/proton/templates/" + lang;
            if (Posix.system(@"cp -r '$tp' '$path'") != 0)
            {
                warning("Could not create project from template");
                return;
            }
        }
        else
        {
            var f = GLib.File.new_for_path(path);

            try { f.make_directory(); }
            catch (Error e)
            {
                warning(e.message);
                return;
            }
        }

        if (FileUtils.test(path + "/template_setup.sh", FileTest.EXISTS))
        {
            string pname = np_name_entry.get_text();
            string cmd   = @"/bin/bash '$path/template_setup.sh' $pname";
            if (Posix.system(cmd) != 0)
            {
                warning("Could not properly setup your template");
            }
        }

        if (this.np_git_switch.active &&
            Posix.system(@"cd '$path' && git init") != 0)
        {
            warning("Failed to initialize git repo");
        }

        this.safe_spawn_and_close(this.application, new File(path));
    }

    bool validate_np(out string? _path, out string? lang)
    {
        string? path = np_file_chooser_button.get_filename();
        string text  = np_name_entry.get_text();
        string error = null;

        _path = null;
        lang = null;

        np_error_label.set_visible(false);

        if (text == "" || path == null)
            error = "Empty project name or path";
        else if (!FileUtils.test(path, FileTest.IS_DIR))
            error = "Invalid project path";
        else if (FileUtils.test(path + "/" + text, FileTest.EXISTS))
            error = "Project exists";
        else
        {
            Gtk.TreeIter it;

            if (np_language_combo.get_active_iter(out it))
                np_language_list_store.get(it, 0, out lang);
            _path = path + "/" + text;
            return (true);
        }

        np_error_label.set_label(error);
        np_error_label.set_visible(true);

        return (false);
    }

    void load_templates()
    {
        try
        {
            string? fname = null;
            string  dname = Constants.DATADIR + "/proton/templates";
            var dir       = Dir.open(dname);
            Gtk.TreeIter iter;

            while ((fname = dir.read_name()) != null)
            {
                if (!FileUtils.test(@"$dname/$fname", FileTest.IS_DIR))
                    continue; // Don't load anything that is not a folder
                this.np_language_list_store.append(out iter);
                this.np_language_list_store.set(iter, 0, fname, -1);
                debug("Added template: %s", fname);
            }
        }
        catch (Error e)
        {
            warning(e.message);
            warning("[Proton] Could not load templates");
        }
    }

    private void safe_spawn_and_close(Gtk.Application app, File f)
    {
        Window win = null;

        settings.add_recent(f.path);
        app.window_added.connect((w) => {
            w.show();
            destroy();
        });
        win = new Window(app, f);
    }

    [GtkCallback]
    void on_open_templates_clicked()
    {
        try
        {
            string path = Constants.DATADIR + "/proton/templates";
            string cmd = @"/usr/bin/xdg-open $path";

            Process.spawn_command_line_sync(cmd, null, null, null);
        }
        catch (Error e)
        {
            warning(e.message);
        }
    }
}
