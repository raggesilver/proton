/* Settings.vala
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

public class Proton.Settings : Marble.Settings
{
    private static Proton.Settings? instance = null;

    public bool     dark_mode            { get; set; }
    public bool     transparency         { get; set; }
    public int      width                { get; set; }
    public int      height               { get; set; }
    public int      pos_x                { get; set; }
    public int      pos_y                { get; set; }
    public string[] recent_projects      { get; set; }
    public int      bottom_panel_height  { get; set; }
    public int      left_panel_width     { get; set; }
    public bool     bottom_panel_visible { get; set; }
    public bool     left_panel_visible   { get; set; }

    private Settings()
    {
        base("com.raggesilver.Proton");
    }

    /*
     * I decided it is better to only have one instance of the settings class
     * because all project related settings should be stored in .proton/ and IDE
     * customizations such as theme and panels visibility (things that shouldn't
     * change on multiple windows at the same time) should only be saved on exit
     */

    public static Proton.Settings get_instance()
    {
        if (instance == null)
            instance = new Proton.Settings();
        return instance;
    }

    public void add_recent(string s)
    {
        string[] _recent = {};
        _recent += s;
        foreach (var item in recent_projects)
        {
            if (!(item in _recent))
                _recent += item;
            if (_recent.length > 4)
                break ;
        }
        recent_projects = _recent;
    }
}

