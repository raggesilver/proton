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

    public Editor(string? path, uint id) {
        sview = new Gtk.SourceView();
        sview.show();
        this.id = id;

        editor_apply_settings();
        update_ui();

        if (path != null) {
            file = new Proton.File(path);
            open();
        }

        // TODO make this optional
        sview.parent_set.connect((_) => {

            // Prevents on window close critical error messages
            if (sview.parent == null || _ != null)
                return ;

            Gtk.TextIter it;
            int lh;

            sview.buffer.get_start_iter(out it);
            sview.get_line_yrange(it, null, out lh);

            var scroller = this.sview.parent.parent;
            this.sview.bottom_margin = scroller.get_allocated_height() - lh;

            scroller.size_allocate.connect((a) => {
                sview.buffer.get_start_iter(out it);
                sview.get_line_yrange(it, null, out lh);
                sview.bottom_margin = a.height - lh;
            });
        });
    }

    public void update_ui() {
        (sview.buffer as Gtk.SourceBuffer).style_scheme =
            Gtk.SourceStyleSchemeManager.get_default()
                .get_scheme(settings.style_id);
    }

    // TODO use some actual settings
    private void editor_apply_settings() {
        sview.set_monospace(true);
        sview.set_auto_indent(true);
        sview.set_insert_spaces_instead_of_tabs(true);
        sview.set_indent_width(4);
        sview.set_smart_backspace(true);
        sview.set_smart_home_end(Gtk.SourceSmartHomeEndType.ALWAYS);
        sview.set_show_line_numbers(true);
        sview.set_left_margin(5);
        sview.set_right_margin(5);
        sview.set_show_right_margin(true);
        sview.right_margin_position = 80;
        sview.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
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

    public async bool save() {
        string content = get_text();
        bool _saved = yield file.write_async(content);
        if (_saved) {
            last_saved_content = content;
            update_modified();
        }
        return (_saved);
    }

    private string get_text () {
        Gtk.TextIter s, e;
        sview.buffer.get_start_iter (out s);
        sview.buffer.get_end_iter (out e);

        return sview.buffer.get_text (s, e, true);
    }
}
