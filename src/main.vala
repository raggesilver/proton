/* main.vala
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

int main (string[] args) {

    var app = new Gtk.Application ("com.raggesilver.Proton",
        ApplicationFlags.HANDLES_OPEN);

    app.activate.connect (() => {
        stdout.printf("Provide a directory.\n");
    });

    app.open.connect ((files, hint) => {
        var win = app.active_window;
        if (win == null) {
            win = new Proton.Window (app, files[0]);
        }
        win.present ();
    });

    return app.run (args);
}
