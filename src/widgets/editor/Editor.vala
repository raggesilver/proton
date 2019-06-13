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

public class Proton.Editor : Object
{
    public signal void modified(bool is_modified);
    public signal void ui_modified();
    public signal void destroy();
    public signal bool before_save();

    private uint    id;
    private string? last_saved_content = null;
    public File?    file               { get; set; default = null; }
    public bool     is_modified        { get; private set; default = false; }

    public Gtk.SourceView     sview    { get; private set; }
    public Gtk.SourceLanguage language { get; private set; }
    public Gtk.Widget         container;

    public Editor(string? path, uint id)
    {
        sview = new Gtk.SourceView();
        sview.show();
        this.id = id;

        editor_apply_settings();
        update_ui();

        add_completion_words();

        if (path != null) {
            file = new Proton.File(path);
            open();
        }

        // FIXME this is a terrible temporary solution to gutter padding
        var gt = sview.get_gutter(Gtk.TextWindowType.LEFT);
        var rend = gt.get_renderer_at_pos(5, 5);
        if (rend != null)
        {
            var ic_rend = new Gtk.SourceGutterRendererPixbuf();
            ic_rend.set_padding(5, -1);
            gt.insert(ic_rend, 0);
            gt.reorder(rend, 1);
            rend.set_padding(10, -1);
        }

        // TODO make this optional
        sview.parent_set.connect((_) => {

            // Prevents on window close critical error messages
            if (sview.parent == null || _ != null)
                return ;

            container = sview.parent;

            container.size_allocate.connect(adjust_margin);

            sview.size_allocate.connect(adjust_margin);

            sview.event.connect((e) => {
                if (e.type == Gdk.EventType.VISIBILITY_NOTIFY)
                    adjust_margin();
                return (false);
            });
        });
    }

    // TODO make this optional
    void add_completion_words()
    {
        var comp = new Gtk.SourceCompletionWords("Completion", null);
        comp.register(sview.buffer);

        try
        {
            if (!sview.completion.add_provider(comp))
                warning("Could not add completion provider.");
        }
        catch (Error e)
        {
            warning(e.message);
        }
    }

    void adjust_margin()
    {
        Gtk.TextIter it;
        int lh;

        sview.buffer.get_start_iter(out it);
        sview.get_line_yrange(it, null, out lh);

        if (lh == 0)
            return ;

        var ch = container.get_allocated_height();
        sview.set_bottom_margin(ch - lh);
    }

    public void update_ui()
    {
        (sview.buffer as Gtk.SourceBuffer).style_scheme =
            Gtk.SourceStyleSchemeManager.get_default()
                .get_scheme(settings.style_id);
        ui_modified();
    }

    // TODO use some actual settings
    private void editor_apply_settings()
    {
        sview.set_tab_width(4);
        sview.set_left_margin(5);
        sview.set_right_margin(5);
        sview.set_indent_width(4);
        sview.set_monospace(true);
        sview.set_auto_indent(true);
        sview.set_indent_on_tab(true);
        sview.set_smart_backspace(true);
        sview.right_margin_position = 80;
        sview.set_show_line_numbers(true);
        sview.set_show_right_margin(true);
        sview.set_highlight_current_line(true);
        sview.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
        sview.set_insert_spaces_instead_of_tabs(true);
        sview.set_smart_home_end(Gtk.SourceSmartHomeEndType.ALWAYS);

        sview.space_drawer.set_types_for_locations(
            Gtk.SourceSpaceLocationFlags.ALL, Gtk.SourceSpaceTypeFlags.NONE);

        var type_flags = Gtk.SourceSpaceTypeFlags.NONE;
        var location_flags = Gtk.SourceSpaceLocationFlags.NONE;

        type_flags |= Gtk.SourceSpaceTypeFlags.SPACE;
        type_flags |= Gtk.SourceSpaceTypeFlags.TAB;

        location_flags |= Gtk.SourceSpaceLocationFlags.TRAILING;

        sview.space_drawer.set_types_for_locations(
            location_flags, type_flags);

        sview.space_drawer.set_enable_matrix(true);
    }

    public void _set_language(Gtk.SourceLanguage? _lang = null)
    {
        this.language = _lang;

        if (this.language == null)
        {
            var lm = Gtk.SourceLanguageManager.get_default();
            this.language = lm.guess_language(file.name,
                                              file.content_type);
        }

        if (this.language != null && this.language.get_name() == "Makefile")
            this.sview.set_insert_spaces_instead_of_tabs(false);
        // if (this.language != null)
        (sview.buffer as Gtk.SourceBuffer).set_language(this.language);
    }

    private void open()
    {
        file.read_async.begin((obj, res) => {
            string text = file.read_async.end(res);
            (sview.buffer as Gtk.SourceBuffer).begin_not_undoable_action();
            sview.buffer.set_text(text);
            (sview.buffer as Gtk.SourceBuffer).end_not_undoable_action();
            _set_language();

            if (last_saved_content == null)
            {
                last_saved_content = text;
                sview.buffer.changed.connect(update_modified);
            }
            else
                last_saved_content = text;

            adjust_margin();
        });
    }

    private void update_modified()
    {
        var im = (bool) (get_text() != last_saved_content);

        if (im != is_modified)
        {
            is_modified = im;
            modified(is_modified);
        }
    }

    public async bool save()
    {
        if (!is_modified)
            return (true);

        if (before_save())
            return (true);

        string content = get_text();
        bool _saved = yield file.write_async(content);

        if (_saved)
        {
            last_saved_content = content;
            update_modified();
        }

        return (_saved);
    }

    public string get_text()
    {
        Gtk.TextIter s, e;
        sview.buffer.get_bounds(out s, out e);

        return (sview.buffer.get_text(s, e, true));
    }
}
