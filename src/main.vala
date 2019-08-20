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

int main (string[] args)
{
    var app = new Proton.Application();

    app.activate.connect(() => {
        var win = new Proton.OpenWindow(app);
        win.show();
    });

    app.open.connect((files, hint) => {

        if (files.length != 1)
        {
            error("Provide one directory");
        }

        var f = new Proton.File(files[0].get_path());

        if (!f.is_directory)
        {
            error("Provide one directory");
        }

        var win = new Proton.Window(app, f);
        win.show();
    });

    return app.run(args);
}
