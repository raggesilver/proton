/* EditorManager.vala
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

public class Proton.EditorSettings : Marble.Settings
{
    private static Proton.EditorSettings? instance = null;

    public string font_family { get; set; }
    public string style_id    { get; set; }
    public bool   scroll_over { get; set; }

    private EditorSettings()
    {
        base("com.raggesilver.Proton.editor");
    }

    /*
     * I decided it is better to only have one instance of the settings class
     * because all project related settings should be stored in .proton/ and IDE
     * customizations such as theme and panels visibility (things that shouldn't
     * change on multiple windows at the same time) should only be saved on exit
     */

    public static Proton.EditorSettings get_instance()
    {
        if (instance == null)
            instance = new Proton.EditorSettings();
        return instance;
    }
}


public class Proton.EditorManager : Object
{
    public signal void changed(Editor? editor);
    public signal void modified(bool is_modified);
    public signal void created(Editor editor);

    public Editor? current_editor { get; private set; }
    public weak Window win { get; private set; }

    private HashTable<string, Editor> _editors;
    public HashTable<string, Editor> editors {
        get {
            return _editors;
        }
    }

    EditorSettings _settings = EditorSettings.get_instance();

    public EditorManager(Window _win)
    {
        win = _win;
        _editors = new HashTable<string, Editor> (str_hash, str_equal);

        var mgr = Gtk.SourceStyleSchemeManager.get_default();

        mgr.append_search_path(Environment.get_home_dir() +
            "/.local/share/gtksourceview-4/styles"
        );

        mgr.append_search_path(Constants.DATADIR + "/proton/themes");

        _settings.notify.connect((p) => {
            update_ui();
        });

        var save_command = new Command(_win, "File", "save", null, () => {
            save();
        });

        win.command_palette.add_command(save_command);
    }

    private Editor new_editor(File f)
    {
        var e = new Editor(f.path, _editors.size() + 1);

        e.modified.connect((is_modified) => {
            if (current_editor != null &&
                File.equ(current_editor.file, e.file))
            {
                modified(is_modified);
            }
        });

        e.sview.focus_in_event.connect((ev) => {
            current_editor = e;
            modified(e.is_modified);
            changed(e);
            return false;
        });

        e.destroy.connect(() => {
            _editors.remove(e.file.path);
        });

        return e;
    }

    public Editor open(File f)
    {
        Editor? ed = get_editor(f);

        if (ed == null)
        {
            ed = new_editor(f);
            _editors.insert(f.path, ed);
            created(ed);
        }

        current_editor = ed;
        modified(ed.is_modified);
        changed(ed);

        return ed;
    }

    public Editor? get_editor(File f)
    {
        Editor? ed = null;

        _editors.foreach((key, val) => {
            if (val.file != null && File.equ(f, val.file)) {
                ed = val;
                return ;
            }
        });

        return (ed);
    }

    public void connect_accels(Gtk.AccelGroup ac)
    {
        ac.connect (Gdk.keyval_from_name ("s"),
                    Gdk.ModifierType.CONTROL_MASK,
                    0,
                    save);
    }

    public bool save()
    {
        if (current_editor != null && current_editor.file != null)
            current_editor.save.begin();
        return (false);
    }

    public void update_ui()
    {
        _editors.foreach((_, val) => {
            val.update_ui();
        });
    }

    public void renamed(string old, string _new)
    {
        bool is_cur = false;

        Editor? ed = _editors.get(old);

        if (ed != null)
        {
            is_cur = (current_editor != null
                        && File.equ(current_editor.file, ed.file));

            _editors.steal(old);
            ed.file = new File(_new);
            ed.set_language(null);
            _editors.set(_new, ed);

            current_editor = ed;
            changed(ed);
            modified(ed.is_modified);
        }
    }
}
