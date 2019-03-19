/* Editor.vala
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

public class Proton.Editor : Object {

    public signal void modified(bool is_modified);

    private uint id;
    private string? last_saved_content = null;
    public Proton.File? file { get; private set; }
    public bool is_modified { get; private set; default = false; }

    public Gtk.SourceView sview { get; private set; }
    public Gtk.SourceLanguage language { get; private set; }

    public Gtk.Widget container;

    public Editor (string? path, uint id) {
        this.sview = new Gtk.SourceView ();
        this.sview.show ();
        this.id = id;

        editor_apply_settings ();

        if (path != null) {
            this.file = new Proton.File (path);
            open ();
        }
    }

    // TODO use some actual settings
    private void editor_apply_settings () {
        this.sview.set_monospace (true);
        this.sview.set_insert_spaces_instead_of_tabs (true);
        this.sview.set_indent_width (4);
        this.sview.set_smart_backspace (true);
        this.sview.set_smart_home_end (Gtk.SourceSmartHomeEndType.ALWAYS);
    }

    private void _set_language(Gtk.SourceLanguage? _lang) {
        this.language = _lang;

        if (this.language == null) {
            var lm = Gtk.SourceLanguageManager.get_default();
            this.language = lm.guess_language(file.name,
                                              file.content_type);
        }

        if (this.language != null && this.language.get_name() == "Makefile")
            this.sview.set_insert_spaces_instead_of_tabs(false);
        // if (this.language != null)
        (sview.buffer as Gtk.SourceBuffer).set_language(this.language);
    }

    private void open () {
        file.read_async.begin ((obj, res) => {
            string text = file.read_async.end (res);
            sview.buffer.set_text (text);
            _set_language (null);

            if (last_saved_content == null) {
                last_saved_content = text;
                stdout.printf ("Connected modified signal\n");
                sview.buffer.changed.connect (update_modified);
            }
            else
                last_saved_content = text;
        });
    }

    private void update_modified () {
        var im = (bool) (get_text () != last_saved_content);

        if (im != is_modified) {
            is_modified = im;
            modified (is_modified);
        }
    }

    public void save () {
        string content = get_text ();
        file.write_async.begin (content, (obj, res) => {
            file.write_async.end (res);
            last_saved_content = content;
            update_modified ();
            stdout.printf ("File %s saved.\n", file.name);
        });
    }

    private string get_text () {
        Gtk.TextIter s, e;
        sview.buffer.get_start_iter (out s);
        sview.buffer.get_end_iter (out e);

        return sview.buffer.get_text (s, e, true);
    }
}
