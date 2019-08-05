/* PluginSettings.vala
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

public class Proton.PluginSettings : Granite.Services.Settings
{
    private static PluginSettings? instance = null;

    public string[] disabled { get; set; }

    private PluginSettings()
    {
        base("com.raggesilver.Proton.plugins");
    }

    public static PluginSettings get_instance()
    {
        if (instance == null)
            instance = new PluginSettings();

        return (instance);
    }

    public void disable_plugin(string name)
    {
        if (name in this.disabled)
            return ;

        string[] arr = { name };

        foreach (var s in this.disabled)
            arr += s;

        this.disabled = arr;
    }

    public void enable_plugin(string name)
    {
        if (!(name in this.disabled))
            return ;

        string[] arr = {};

        foreach (var s in this.disabled)
        {
            if (s != name)
                arr += s;
        }

        this.disabled = arr;
    }
}
