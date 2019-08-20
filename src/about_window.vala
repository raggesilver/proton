/* about_window.vala
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

public class Proton.AboutWindow : Gtk.AboutDialog
{
    public AboutWindow(Window win)
    {
        this.set_destroy_with_parent(true);
        this.set_transient_for(win);
        this.set_modal(true);

        this.authors = { "Paulo Queiroz" };
        this.translator_credits = null;

        this.program_name = "Proton";
        this.comments = "Proton, because electron is not enough.";
        this.copyright = "Copyright 2019 Paulo Queiroz";
        this.version = Constants.VERSION;

        this.website = "https://gitlab.com/raggesilver-proton/proton";
        this.website_label = "Gitlab repo";

        this.license_type = Gtk.License.GPL_3_0;

        this.logo_icon_name = "com.raggesilver.Proton";

        this.response.connect((res) => {
            this.destroy();
        });
    }
}
