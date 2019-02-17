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
    s.show_all ();
    return (s);
}

[GtkTemplate (ui = "/com/raggesilver/Proton/window.ui")]
public class Proton.Window : Gtk.ApplicationWindow {

    // [GtkChild]
    // Gtk.Box side_panel_box;

    [GtkChild]
    Gtk.Stack side_panel_stack;

    [GtkChild]
    Gtk.Stack editor_stack;

    Proton.Settings settings;

    public Window (Gtk.Application app, File root) {
        Object (application: app);
        settings = new Proton.Settings (root);
        var l = new Proton.TreeView (root);
        l.show ();
        var ts = new Gtk.ScrolledWindow(null, null);
        ts.add(l);
        ts.show_all();
        side_panel_stack.add_titled (ts, "treeview", "Project");
        side_panel_stack.set_visible_child_name ("treeview");

        l.selected.connect ((f) => {
            if (f.query_file_type (0) == FileType.DIRECTORY)
                return;
            var n = "editor" + f.get_path();
            editor_stack.add_titled (wrap_scroller (new Proton.Editor (f)), n, "Editor");
            editor_stack.set_visible_child_name (n);
        });

        apply_settings ();
    }

    public void apply_settings() {
        var css_provider = new Gtk.CssProvider ();
		css_provider.load_from_resource ("/com/raggesilver/Proton/resources/style.css");

		Gtk.StyleContext.add_provider_for_screen (
			Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);
    }
}

