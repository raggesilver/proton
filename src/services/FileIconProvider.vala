/* FileIconProvider.vala
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

public interface Proton.FileIconProvider : Object
{
    public abstract string get_icon_name_for_file(File f);
}

public class Proton.ProtonIconProvider : Object, Proton.FileIconProvider
{
    public string get_icon_name_for_file(File f)
    {
        if (f.is_directory)
            return (get_dir_icon_name(f));
        else
            // return (get_file_icon_name(f));
            return ("text-x-generic-symbolic");
    }

    string get_dir_icon_name(File f)
    {
        if (f.name == ".git")
            return ("text-x-git-symbolic");
        else
            return ("folder-symbolic");
    }

    public TreeIcon get_icon_for_file(File file)
    {
        TreeIcon res = new TreeIcon(this.get_icon_name_for_file(file));

        if (res.name == "folder-symbolic")
            res.expanded_name = "folder-open-symbolic";

        return (res);
    }

    /*
    ** Default instance of ProtonIconProvier. Note that it is possible to have
    ** multiple instances of this Class.
    */
    private static ProtonIconProvider? _default = null;
    public static ProtonIconProvider get_default()
    {
        if (_default == null)
            _default = new ProtonIconProvider();

        return (_default);
    }
}

public class Proton.TreeIcon : Object
{
    public Gtk.Image    image   { get; protected set; }
    public string       name    { get; set; }

    public string?      expanded_name   { get; set; default = null; }
    public bool         is_expanded     { get; set; default = false; }

    construct
    {
        this.image = new Gtk.Image();
    }

    public TreeIcon(string name)
    {
        this.notify.connect(this.update_icon);
        this.name = name;
    }

    public void update_icon()
    {
        this.image.set_from_icon_name(
            (this.is_expanded && this.expanded_name != null) ?
                this.expanded_name : this.name,
            Gtk.IconSize.MENU
        );
    }
}
