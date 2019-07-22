/* PluginManager.vala
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
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
