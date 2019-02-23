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

    public signal void changed(Proton.Editor? editor);
    public signal void modified(bool is_modified);

    private static Proton.EditorManager? instance = null;
    public Proton.Editor? current_editor;

    private GLib.HashTable<string, Proton.Editor> _editors;
    public GLib.HashTable<string, Proton.Editor> editors {
        get {
            return _editors;
        }
    }

    private EditorManager() {
        _editors = new GLib.HashTable<string, Proton.Editor> (str_hash,
                                                              str_equal);
    }

    private Proton.Editor new_editor(GLib.File f) {
        var e = new Proton.Editor(f.get_path (), _editors.size() + 1);
        e.modified.connect ((is_modified) => {
            if (current_editor != null && Proton.File.equ(current_editor.file,
                                                      e.file)) {
                modified (is_modified);
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

    public Proton.Editor open(GLib.File f) {
        Proton.Editor? ed = null;

        _editors.foreach((key, val) => {
            if (val.file != null && val.file.file.equal(f)) {
                ed = val;
                return ;
            }
        });

        if (ed == null) {
            ed = new_editor(f);
            _editors.insert(f.get_path (), ed);
        }
        return ed;
    }

    public static Proton.EditorManager get_instance() {
        if (instance == null)
            instance = new Proton.EditorManager ();
        return instance;
    }

    public void connect_accels (Gtk.AccelGroup ac) {
        ac.connect (Gdk.keyval_from_name ("s"),
                    Gdk.ModifierType.CONTROL_MASK,
                    0,
                    save);
    }

    public bool save () {
        if (current_editor != null && current_editor.file != null) {
            current_editor.save ();
        }
        return false;
    }
}

