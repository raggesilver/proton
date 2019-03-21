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

public interface Proton.IPlugin : Object {
    public abstract void activate(Window window);
    public abstract void deactivate();
}

public class Proton.Plugin : TypeModule {
    [CCode (has_target=false)]
    private delegate Type PluginInitFunction (TypeModule module);
    private Module module = null;
    private string name = null;

    public Plugin(string name) {
        this.name = name;
    }

    public override bool load() {
        string path = Module.build_path("/home/pqueiroz/Projects/proton/_native_build/src/plugins/editorconfig", name);
        module = Module.open(path, ModuleFlags.BIND_LAZY);
        if (null == module) {
            error ("Module not found");
        }

        void* plugin_init = null;
        if (!module.symbol("plugin_init", out plugin_init)) {
            error("No such symbol");
        }

        ((PluginInitFunction) plugin_init)(this);
        return true;
    }

    public override void unload() {
        module = null;
        message("Library unloaded");
    }
}

//  public class Proton.PluginManager : Object {

//      public PluginManager() {

//      }

//      public void load_plugin(string name) {

//      }
//  }
