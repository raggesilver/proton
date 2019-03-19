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

namespace Proton {
    public File root;
    public Core core;

    int main (string[] args) {

        var app = Application.instance;

        app.activate.connect (() => {
            // FIXME crete a welcome window
            stdout.printf("Provide a directory.\n");
        });

        app.open.connect((files, hint) => {

            if (files.length != 1) {
                error("Provide one directory");
            }

            var f = new File(files[0].get_path());

            if (!f.is_directory) {
                error("Provide one directory");
            }

            var win = app.active_window;
            if (win == null) {
                root = f;
                core = Core.get_instance();
                win = new Window(app);
            }

            win.show();
        });

        return app.run (args);
    }
}
