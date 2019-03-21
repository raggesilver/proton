/* editorconfig.vala
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

class Editorconfig : Object, Proton.IPlugin {

    public void activate(Proton.Window w) {
        stdout.printf("Activated\n");
        w.set_title("Proton - La batata");
    }

    public void deactivate() {
        stdout.printf("Deactivated\n");
    }

    public Editorconfig() {}
}

[ModuleInit]
public static Type plugin_init(TypeModule module) {
    return typeof(Editorconfig);
}
