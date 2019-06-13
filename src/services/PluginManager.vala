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
	NO_REGISTRATION_FUNCTION,
	FAILED
}

public interface Proton.PluginIface : Object
{
    public abstract void do_register(PluginLoader loader);
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

public class Proton.PluginLoader : Object
{
    [CCode (has_target = false)]
    private delegate Type RegisterPluginFunction(Module module);

    public signal void editor_changed(Editor? ed);

    private PluginIface[]   plugins = {};
    private PluginInfo[]    infos = {};

    public Gtk.Box  left_hb_box     { get; private set; }
    public Gtk.Box  right_hb_box    { get; private set; }
    public string   root_path       { get; private set; }
    public Window   window          { get; private set; }

    public PluginLoader(Window w)
    {
        window = w;
        /*
        ** TODO: These fields should be deprecated, window now is accessible to
        ** plugins.
        */
        left_hb_box = w.left_hb_box;
        right_hb_box = w.right_hb_box;
        root_path = w.root.path;
    }

    public PluginIface load(string path) throws PluginError
    {
        if (!Module.supported())
        {
            throw new PluginError.NOT_SUPPORTED("Plugins are not supported");
        }

        Module module = Module.open(path, ModuleFlags.BIND_LAZY);
        if (module == null)
        {
            throw new PluginError.FAILED(Module.error());
        }

        void *function;
        module.symbol("register_plugin", out function);
        if (function == null)
        {
            throw new PluginError.NO_REGISTRATION_FUNCTION(
                "register_plugin not found");
        }

        var register_plugin = (RegisterPluginFunction) function;
        Type type = register_plugin(module);
        if (type.is_a(typeof(PluginIface)) == false)
        {
            throw new PluginError.UNEXPECTED_TYPE("Unexpected type");
        }

        PluginInfo info = new PluginInfo(type, (owned)module);
        infos += info;

        PluginIface plugin = (PluginIface) Object.new(type);
        plugins += plugin;
        plugin.do_register(this);

        return plugin;
    }
}
