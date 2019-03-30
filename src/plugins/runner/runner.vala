/* runner.vala
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

private class Runner : Object, Proton.PluginIface {

    Gtk.Button btn;
    Gtk.Image play_image;
    Gtk.Image stop_image;

    bool working = false;

    construct {
        play_image = new Gtk.Image.from_icon_name(
            "media-playback-start-symbolic", Gtk.IconSize.MENU);
        stop_image = new Gtk.Image.from_icon_name(
            "media-playback-stop-symbolic", Gtk.IconSize.MENU);
        btn = new Gtk.Button();
    }

    public void do_register(Proton.PluginLoader loader) {
        btn.set_image(play_image);
        btn.show();
        loader.left_hb_box.pack_start(btn);
        loader.left_hb_box.reorder_child(btn, 0);

        btn.clicked.connect(() => {
            Proton.Subprocess sp = null;
            if (!working)
            {
                on_start();
                // var sp = new Proton.FlatpakSubprocess(null,
                //                                       {"sleep", "5"},
                //                                       {},
                //                                       SubprocessFlags.NONE,
                //                                       -1, -1, -1);
                // sp.finished.connect(() => {
                //     on_finish();
                // });

                sp = new Proton.Subprocess({"sleep", "5"}, SubprocessFlags.NONE);
                sp.start();
                sp.finished.connect((ret) => {
                   on_finish();
                   print("Exited with code %d\n", ret);
                });
            } else {
                sp.kill();
            }
        });
    }

    void on_start() {
        btn.set_image(stop_image);
        working = true;
    }

    void on_finish() {
        btn.set_image(play_image);
        working = false;
    }

    public void activate() {
    }

    public void deactivate() {
    }
}

public Type register_plugin (Module module) {
    return typeof(Runner);
}
