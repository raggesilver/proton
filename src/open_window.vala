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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/open_window.ui")]
public class Proton.OpenWindow : Gtk.ApplicationWindow {

    // [GtkChild]
    // Gtk.HeaderBar header_bar;

    [GtkChild]
    Gtk.Button clone_project_button;

    [GtkChild]
    Gtk.Button new_project_button;

    [GtkChild]
    Gtk.Button back_button;

    [GtkChild]
    Gtk.Button open_other_button;

    [GtkChild]
    Gtk.Label no_recent_label;

    [GtkChild]
    Gtk.Label version_label;

    [GtkChild]
    Gtk.Box recent_box;

    [GtkChild]
    Gtk.Box recent_vbox;

    [GtkChild]
    Gtk.FileChooserButton new_project_file_chooser_button;

    [GtkChild]
    Gtk.Stack stack;

    public OpenWindow(Gtk.Application app) {
        Object(application: app);

        new_project_file_chooser_button.set_uri("Projects");

        clone_project_button.clicked.connect(() => {
            modal = false;
            get_style_context().remove_class("open-window");
            back_button.show();
            stack.set_visible_child_name("clone_page");
        });

        back_button.clicked.connect(() => {
            modal = true;
            get_style_context().add_class("open-window");
            back_button.hide();
            stack.set_visible_child_name("welcome_page");
        });

        new_project_button.clicked.connect(() => {
            modal = false;
            get_style_context().remove_class("open-window");
            back_button.show();
            stack.set_visible_child_name("new_project_page");
        });

        open_other_button.clicked.connect(() => {
            var d = new Gtk.FileChooserDialog(
                "Project folder",
                this,
                Gtk.FileChooserAction.SELECT_FOLDER,
                "Cancel", Gtk.ResponseType.CANCEL,
                "_Open", Gtk.ResponseType.OK,
                null);
            var res = d.run();

            if (res == Gtk.ResponseType.OK) {
                var f = new File(d.get_filename());
                stdout.printf("Open path %s\n", f.path);
                root = f;
                settings.add_recent(f.path);
                var w = new Window(this.get_application());
                w.show();
                d.destroy();
                destroy();
            }

            d.destroy();
        });

        update_ui();

        get_recent();
    }

    private void update_ui() {
        var css_provider = new Gtk.CssProvider();
        css_provider.load_from_resource(
            "/com/raggesilver/Proton/resources/style.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        version_label.set_text(@"Version $(Constants.VERSION)");
    }

    private Gtk.Button new_recent_row(File f) {
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
            root = f;
            settings.add_recent(f.path);
            var w = new Window(this.application);
            w.show();
            destroy();
        });

        r.add(b);
        r.show_all();
        r.set_relief(Gtk.ReliefStyle.NONE);

        return (r);
    }

    private void get_recent() {
        string[] recent = settings.recent_projects;
        bool has_recent = false;
        File f;

        foreach (var s in recent) {
            f = new File(s);

            if (f.exists && f.is_directory) {
                has_recent = true;
                recent_vbox.pack_start(new_recent_row(f), false, true, 0);
            }
        }

        if (has_recent) {
            no_recent_label.hide();
            recent_box.show();
        }
    }
}
