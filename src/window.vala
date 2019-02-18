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

[GtkTemplate (ui = "/com/raggesilver/Proton/window.ui")]
public class Proton.Window : Gtk.ApplicationWindow {

    // [GtkChild]
    // Gtk.Box side_panel_box;

    [GtkChild]
    Gtk.Stack side_panel_stack;

    // [GtkChild]
    // Gtk.Stack editor_stack;

    public Proton.Settings settings;
    public Proton.TreeView tree_view;

    public Window (Gtk.Application app, File root) {

        Object (application: app);

        // Initialize stuff
        settings = Proton.Settings.get_instance ();
        tree_view = new Proton.TreeView (root);

        set_default_size (settings.width,
                          settings.height);

        int x = settings.get_instance ().pos_x;
        int y = settings.get_instance ().pos_y;

        if (x != -1 && y != -1) {
            move (x, y);
        } else {
            x = (Gdk.Screen.width () - default_width) / 2;
            y = (Gdk.Screen.height () - default_height) / 2;
            move (x, y);
        }

        build_ui ();

        // Connect events
        tree_view.selected.connect (tree_view_selected);
        delete_event.connect (on_delete);

        apply_settings ();
    }

    private void build_ui() {
        side_panel_stack.add_titled (wrap_scroller (tree_view),
                                     "treeview",
                                     "Project");
        side_panel_stack.set_visible_child_name ("treeview");
    }

    private void tree_view_selected(File f) {
        /*if (f.query_file_type (0) == FileType.DIRECTORY)
            return ;

        var c = new Proton.Container (wrap_scroller (new Proton.Editor (f)),
                                      true);
        editor_stack.add_titled (c, "editor" + f.get_path(), "Editor");
        editor_stack.set_visible_child (c);

        GLib.Timeout.add(500, () => {
            c.set_working (false);
            return false;
        });*/
    }

    private bool on_delete() {
        int width, height;
        this.get_size (out width, out height);
        settings.width = width;
        settings.height = height;

        int pos_x, pos_y;
        get_position (out pos_x, out pos_y);
        settings.pos_x = pos_x;
        settings.pos_y = pos_y;

        return false;
    }

    public void apply_settings() {
        var css_provider = new Gtk.CssProvider ();
		css_provider.load_from_resource ("/com/raggesilver/Proton/resources/style.css");

		Gtk.StyleContext.add_provider_for_screen (
			Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);
    }
}

