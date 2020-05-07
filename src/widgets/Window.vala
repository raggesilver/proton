/* Window.vala
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

[GtkTemplate (ui = "/com/raggesilver/Proton/layouts/window.ui")]
public class Proton.Window : Gtk.ApplicationWindow {

    // public Gtk.HeaderBar header_bar { get; construct; }

    [GtkChild] Gtk.StackSwitcher side_panel_switcher;
    [GtkChild] Gtk.Button play_button;
    [GtkChild] Gtk.MenuButton build_menu_button;
    [GtkChild] Gtk.Revealer pause_revealer;

    private bool is_playing = false;

    construct {
        // this.header_bar = new Gtk.HeaderBar();
        // this.header_bar.set_title("Proton 2");
        // this.header_bar.show_close_button = true;
        // this.set_titlebar(this.header_bar);
    }

    public Window (Gtk.Application app) {
        Object (application: app);

        this.side_panel_switcher.homogeneous = true;

        this.show_all();
    }

    ~Window () {
        message("I was destroyed");
    }

    [GtkCallback]
    private void on_play () {
        var img = this.play_button.get_child() as Gtk.Image;

        img.set_from_icon_name(this.is_playing ?
            "media-playback-start-symbolic" : "media-playback-stop-symbolic",
            Gtk.IconSize.MENU
        );
        this.is_playing = !this.is_playing;
        this.pause_revealer.reveal_child = this.is_playing;
        this.build_menu_button.sensitive = !this.is_playing;
    }
}
