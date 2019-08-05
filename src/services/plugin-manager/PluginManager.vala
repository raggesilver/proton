/* PluginManager.vala
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

/*
** Reference: https://valadoc.org/gmodule-2.0/GLib.Module.html
*/

public errordomain Proton.PluginError
{
	NOT_SUPPORTED,
	UNEXPECTED_TYPE,
	NO_REGISTER_FUNCTION,
	FAILED
}

public interface Proton.PluginIface : Object
{
    public abstract void do_register(PluginManager pm);
    public abstract void activate();
    public abstract void deactivate();

    public abstract bool   active           { get; protected set; }
    public abstract string name             { get; protected set; }
    public abstract string repo_url         { get; protected set; }
    public abstract Gtk.Widget? plugin_page {
        get; protected set; default = null;
    }

}

public class Proton.PluginInfo : Object
{
    public Module module;
    public Type   gtype;

    internal PluginInfo(Type type, owned Module module)
    {
        this.module = (owned)module;
        this.gtype = type;
    }
}

public class Proton.Plug
{
    public PluginIface iface { get; internal set; }
    public PluginInfo  info  { get; internal set; }
}

public class Proton.PluginManager : Object
{
    [CCode (has_target = false)]
    private delegate Type RegisterPluginFunction(Module module);

    private Mutex          mutex = Mutex();
    private Array<Plug>    plugs;
    private PluginSettings settings = PluginSettings.get_instance();

    public weak Window window { get; private set; }

    public PluginManager(Window window)
    {
        this.window = window;
        this.plugs = new Array<Plug>();
    }

    public async void load()
    {
        return ;
        SourceFunc callback = load.callback;

        new Thread<bool>("plugin_manager_load", () => {
            try { do_load(); }
            catch(Error e) { error("Error: %s.", e.message); }
            Idle.add((owned)callback);
            return (true);
        });

        yield;
    }

    private void do_load() throws Error
    {
        if (!Module.supported())
            throw new PluginError.NOT_SUPPORTED("Plugins are not supported");

        // Iterate through plugindir and load plugins
        var dir = Dir.open(Constants.PLUGINDIR);
        string? fname = null;

        while (null != (fname = dir.read_name()))
        {
            var f = new File(
                Constants.PLUGINDIR + Path.DIR_SEPARATOR_S + fname);

            var p = load_plugin(f);

            if (p != null)
            {
                if (p.iface.name in this.settings.disabled)
                {
                    debug("[PluginManager] plugin %s disabled, skipping...",
                        fname);
                }
                else
                {
                    p.iface.activate();
                    debug("Plugin '%s' loaded.", f.name);
                }
            }
        }
    }

    private Plug? load_plugin(File f)
    {
        var pa = f.path + Path.DIR_SEPARATOR_S + "lib" + f.name;
        var module = Module.open(pa, ModuleFlags.LAZY);

        if (module == null)
        {
            warning("Failed to load plugin '%s'", f.path);
            warning("%s", Module.error());
            return (null);
        }

        void *function;
        module.symbol("register_plugin", out function);
        if (function == null)
        {
            warning("Plugin '%s' has no register funcion", f.name);
            return (null);
        }

        var register_plugin = (RegisterPluginFunction)function;
        var type = register_plugin(module);

        if (type.is_a(typeof(PluginIface)) == false)
        {
            warning("Weird type for plugin '%s'", f.name);
            return (null);
        }

        PluginInfo info = new PluginInfo(type, (owned)module);

        var iface = (PluginIface)Object.new(type);
        iface.do_register(this);

        var p = new Plug();
        p.iface = iface;
        p.info = info;

        mutex.lock();
        plugs.append_val(p);
        mutex.unlock();

        return (p);
    }

    public void disable(Proton.Plug plugin)
    {
        plugin.iface.deactivate();
        this.settings.disable_plugin(plugin.iface.name);
    }

    public Plug[] get_plugins()
    {
        return (this.plugs.data);
    }
}
