/* PeasManager.vala
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

public interface Proton.PeasPlugin : Object, Peas.Activatable
{
}

public class Proton.PeasManager : Object
{
    private Peas.Engine       engine;
    private Peas.ExtensionSet ext_set;

    public weak Window window { get; protected set; }

    public PeasManager(Window window)
    {
        this.window = window;

        this.engine = new Peas.Engine();

        this.ext_set = new Peas.ExtensionSet(this.engine,
                                             typeof(Peas.Activatable),
                                             "object",
                                             this.window,
                                             null);

        this.ext_set.extension_added.connect(this.on_ext_added);

        this.engine.add_search_path(Constants.PLUGINDIR, null);
        this.engine.enable_loader("python3");
        this.engine.rescan_plugins();

        weak List<Peas.PluginInfo>? lst = this.engine.get_plugin_list();

        if (lst == null)
            return ;

        this.load(lst);
    }

    private void on_ext_added(Peas.ExtensionSet ext_set,
                              Peas.PluginInfo   info,
                              Object            exten)
    {
        warning("[PeasManager] ext called");

        var act = exten as Peas.Activatable;
        act.activate();
    }

    private void load(List<Peas.PluginInfo> lst)
    {
        for (uint i = 0; i < lst.length(); i++)
        {
            var name = lst.nth(i).data.get_name();
            debug("Plugin %s", name);

            if (name == "Git")
            {
                var b = this.engine.try_load_plugin(lst.nth(i).data);
                debug("Loading git = %s", b.to_string());
            }
        }
    }
}
