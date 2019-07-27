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
}

private class Proton.PluginInfo : Object
{
    public Module module;
    public Type gtype;

    public PluginInfo(Type type, owned Module module)
    {
        this.module = (owned) module;
        this.gtype = type;
    }
}

private class Proton.Plug
{
    public PluginIface iface;
    public PluginInfo  info;
}

public class Proton.PluginManager : Object
{
    [CCode (has_target = false)]
    private delegate Type RegisterPluginFunction(Module module);

    // Private
    Plug[] plugs = {};

    // Public
    public Window window { get; private set; }

    public PluginManager(Window window)
    {
        this.window = window;
    }

    public async void load()
    {
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
                p.iface.activate();

                debug("Plugin '%s' loaded.", f.name);
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
        }

        PluginInfo info = new PluginInfo(type, (owned)module);

        var iface = (PluginIface)Object.new(type);
        iface.do_register(this);

        var p = new Plug();
        p.iface = iface;
        p.info = info;

        Idle.add(() => {
            plugs += p;
            return (false);
        });

        return (p);
    }
}
