/* EditorManager.vala
 *
 * Copyright 2019 Paulo Queiroz <unknown@domain.org>
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

public class Proton.EditorManager : Object {

    public signal void changed(Editor? editor);
    public signal void modified(bool is_modified);

    private static EditorManager? instance = null;
    public Editor? current_editor;

    private HashTable<string, HashTable<string, string>> configs;
    private HashTable<string, Editor> _editors;
    public HashTable<string, Editor> editors {
        get {
            return _editors;
        }
    }

    private EditorManager() {
        _editors = new HashTable<string, Editor> (str_hash, str_equal);

        configs = new HashTable<string, HashTable<string, string>>
            (str_hash, str_equal);

        var mgr = Gtk.SourceStyleSchemeManager.get_default();
        mgr.append_search_path(
            Environment.get_home_dir() + "/.local/share/gtksourceview-4/styles");

        settings.notify.connect((p) => {
            print("%s\n", p.get_name());
            if (p.get_name() == "style-id") {
                update_ui();
            }
        });
    }

    private Editor new_editor(File f) {
        var e = new Editor(f.path, _editors.size() + 1);

        e.modified.connect((is_modified) => {
            if (current_editor != null &&
                File.equ(current_editor.file, e.file))
            {
                modified(is_modified);
            }
        });

        e.sview.focus_in_event.connect ((ev) => {
            current_editor = e;
            modified (e.is_modified);
            changed (e);
            return false;
        });

        return e;
    }

    public Editor open(File f) {
        Editor? ed = null;

        _editors.foreach((key, val) => {
            if (val.file != null && File.equ(f, val.file)) {
                ed = val;
                return ;
            }
        });

        if (ed == null) {
            ed = new_editor(f);
            _editors.insert(f.path, ed);
        }

        return ed;
    }

    public static EditorManager get_instance() {
        if (instance == null)
            instance = new EditorManager ();
        return instance;
    }

    public void connect_accels(Gtk.AccelGroup ac) {
        ac.connect (Gdk.keyval_from_name ("s"),
                    Gdk.ModifierType.CONTROL_MASK,
                    0,
                    save);
    }

    public bool save() {
        if (current_editor != null && current_editor.file != null) {
            current_editor.save.begin();
        }
        return false;
    }

    public void update_ui() {
        _editors.foreach((_, val) => {
            val.update_ui();
        });
    }
}

