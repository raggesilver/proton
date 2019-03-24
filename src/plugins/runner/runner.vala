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

private static bool process_line (IOChannel channel, IOCondition condition, string stream_name) {
	if (condition == IOCondition.HUP) {
		print("%s: The fd has been closed.\n", stream_name);
		return false;
	}

	try {
		string line;
		channel.read_line(out line, null, null);
		print("%s: %s", stream_name, line);
	} catch(IOChannelError e) {
		print("%s: IOChannelError: %s\n", stream_name, e.message);
		return false;
	} catch(ConvertError e) {
		print("%s: ConvertError: %s\n", stream_name, e.message);
		return false;
	}

	return true;
}

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
            if (!working)
            {
                on_start();
                var sp = new Proton.FlatpakSubprocess(null,
                                                      {"sleep", "5"},
                                                      {},
                                                      SubprocessFlags.NONE,
                                                      -1, -1, -1);
                sp.finished.connect(() => {
                    on_finish();
                });
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
