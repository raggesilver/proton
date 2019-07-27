/* Editor.vala
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

public class Proton.Editor : Object
{
    public signal void modified(bool is_modified);
    public signal void ui_modified();
    public signal void destroy();
    public signal bool before_save();

    private uint        id;
    private string?     last_saved_content = null;
    private Gtk.TextTag highlight_tag;

    public File?    file               { get; set; default = null; }
    public bool     is_modified        { get; private set; default = false; }

    public Gtk.SourceView     sview    { get; private set; }
    public Gtk.SourceLanguage language { get; private set; }
    public Gtk.Widget         container;

    EditorSettings _settings = EditorSettings.get_instance();

    public Editor(string? path, uint id)
    {
        this.id = id;

        this.sview = new Gtk.SourceView();
        this.highlight_tag = this.sview.buffer.create_tag(
            // Tag name
            "highlight-tag",
            // null terminaded list of property pairs
            "background", "yellow",
            null
        );

        this.editor_apply_settings();
        this.update_ui();
        this.add_completion_words();

        if (path != null)
        {
            this.file = new Proton.File(path);
            this.open();
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

        var buf = sview.buffer as Gtk.SourceBuffer;
        buf.notify.connect((spec) => {
            Gtk.TextIter buf_siter, buf_eiter, sel_siter, sel_eiter;

            buf.get_bounds(out buf_siter, out buf_eiter);
            buf.remove_tag_by_name("highlight-tag", buf_siter, buf_eiter);

            if (!buf.has_selection)
                return ;

            buf.get_selection_bounds(out sel_siter, out sel_eiter);

            string text = buf.get_text(sel_siter, sel_eiter, false);
            if (text != "")
            {
                this.highlight_selected(text, buf_siter);
            }
        });

        this.sview.show();
    }

    void highlight_selected(string text, Gtk.TextIter start)
    {
        Gtk.TextIter mstart, mend;

        if (start.forward_search(text, 0, out mstart, out mend, null))
        {
            this.sview.buffer.apply_tag(this.highlight_tag, mstart, mend);
            this.highlight_selected(text, mend);
        }
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
                .get_scheme(_settings.style_id);

        var f = Pango.FontDescription.from_string(_settings.font_family);
        if (f.get_family() != null && f.get_family().index_of("None") == -1)
        {
            warning("FAMILY: %s", f.get_family());
            sview.override_font(f);
        }

        /*
        ** Try appying the current theme "search-match" style to the highlight
        ** tag
        */

        {
            var scheme = (this.sview.buffer as Gtk.SourceBuffer).style_scheme;
            var style = scheme.get_style("search-match");

            if (style != null)
            {
                style.apply(this.highlight_tag);
            }
        }

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
