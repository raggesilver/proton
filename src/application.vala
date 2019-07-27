/* application.vala
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

namespace Proton {
    public Settings settings;
}

public class Proton.Application : Gtk.Application {

    construct {
        flags |= ApplicationFlags.HANDLES_OPEN;
        flags |= ApplicationFlags.NON_UNIQUE;
        // TODO man up and use command line
        // flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

        application_id = "com.raggesilver.Proton";
    }

    private Application() {
        settings = Proton.Settings.get_instance ();
    }

    public static Application _instance = null;
    public static Application  instance {
        get {
            if (_instance == null)
                _instance = new Application ();
            return _instance;
        }
    }

}
