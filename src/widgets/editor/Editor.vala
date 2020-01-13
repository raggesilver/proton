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

public class Proton.EditorSearch : Object
{
    public Gtk.SourceSearchContext context { get; private set; }
    public Gtk.SourceSearchSettings settings { get; private set; }

    public int current_result { get; private set; }

    private weak Proton.Editor editor;

    internal EditorSearch(Proton.Editor editor)
    {
        this.editor = editor;

        this.settings = new Gtk.SourceSearchSettings();
        this.context  = new Gtk.SourceSearchContext(this.editor.buffer,
                                                    this.settings);

        // Back at the begining makes the search go to the bottom
        // Forward at the bottom makes the search go to the top
        this.settings.set_wrap_around(true);
        this.context.set_highlight(true);

        this.update_ui();

        // Update UI on editor ui_modified
        this.editor.ui_modified.connect(this.update_ui);
        this.context.notify["occurrences-count"].connect(() => {
            this.update_current_result();
        });
    }

    public void search(string? text)
    {
        this.current_result = 0;
        this.settings.set_search_text(text);
    }

    public bool replace(string text)
    {
        var buf = this.editor.buffer;
        Gtk.TextIter s = {};
        Gtk.TextIter e = {};

        // If nothing is selected or can't get the selection, return
        if (!buf.has_selection || !buf.get_selection_bounds(out s, out e))
            return (false);

        try {
            var r = this.context.replace(s, e, text, text.length);
            return (r);
        }
        catch (Error e) { warning(e.message); }
        return (false);
    }

    public bool replace_all(string text)
    {
        try {
            this.context.replace_all(text, text.length);
            return (true);
        }
        catch (Error e) { warning(e.message); }
        return (false);
    }

    public async bool next(out Gtk.TextIter start,
                           out Gtk.TextIter end)
    {
        Gtk.TextIter cur;

        this.get_cursor_position(out cur);
        try
        {
            var res = yield this.context.forward_async(cur, null,
                                                       out start, out end,
                                                       null);

            if (res)
            {
                this.current_result = this.context
                                          .get_occurrence_position(start, end);
            }

            return (res);
        }
        catch (Error e) { warning(e.message); }
        return (false);
    }

    public async bool prev(out Gtk.TextIter start,
                           out Gtk.TextIter end)
    {
        Gtk.TextIter cur;

        this.get_cursor_position(out cur, true);
        try
        {
            var res = yield this.context.backward_async(cur, null,
                                                        out start, out end,
                                                        null);

            if (res)
            {
                this.current_result = this.context
                                          .get_occurrence_position(start, end);
            }

            return (res);
        }
        catch (Error e) { warning(e.message); }
        return (false);
    }

    public void update_current_result()
    {
        var buf = this.editor.buffer;
        Gtk.TextIter s = {};
        Gtk.TextIter e = {};

        if (buf.has_selection && buf.get_selection_bounds(out s, out e))
        {
            this.current_result = this.context.get_occurrence_position(s, e);
        }
        else
            this.current_result = -1;
    }

    private void update_ui()
    {
        var scheme = this.editor.buffer.style_scheme;

        this.context.set_highlight(false);
        this.context.set_match_style(scheme.get_style("search-match"));
        this.context.set_highlight(true);
    }

    private void get_cursor_position(out Gtk.TextIter iter, bool back = false)
    {
        Gtk.SourceBuffer buf = this.editor.buffer;

        iter = {};

        if (buf.has_selection)
        {
            if (back && buf.get_selection_bounds(out iter, null)) return;
            if (!back && buf.get_selection_bounds(null, out iter)) return;
        }

        buf.get_iter_at_offset(out iter, buf.cursor_position);
    }
}

public class Proton.Editor : Object
{
    // The modified signal now uses this.buffer's builtin modified property,
    // this has an advantage that there is no need to strcmp the whole buffer
    // on every change (which was silly), but it also has the disadvantage that
    // the modified field now doesn't know if the buffer was changed and later
    // on changed back to the initial value.
    public signal void modified(bool is_modified);

    // The ui_modified signal is fired when the CSS, font and/or theme for the
    // view were changed. Necessary for IdeStack.titlebar style updates.
    public signal void ui_modified();

    // TODO: review the need for this signal
    public signal void destroy();

    // This signal is fired right before the file is saved. If any handler
    // returns true the standard file saving method won't occur. Unless your
    // plugin/modification handles this file saving better than the standard
    // implementation you shouldn't return true.
    public signal bool before_save();

    public signal void loading_finished();

    // Performance improvement based on GNOME Builder's implementation
    // https://gitlab.gnome.org/GNOME/gnome-builder/blob/master/
    // src/libide/sourceview/ide-source-view.c cached_char_height
    private int line_height;

    private uint id;
    private string? last_saved_content = null;
    private EditorSettings _settings = EditorSettings.get_instance();

    public File? file { get; set; }
    public bool is_modified { get; private set; }
    public bool is_loading { get; private set; }
    public Gtk.SourceView sview { get; private set; }
    public Gtk.TextTag highlight_tag { get; private set; }
    public Gtk.TextTag search_tag { get; private set; }

    public new Gtk.SourceBuffer buffer;
    public Gtk.SourceLanguage language;

    public Proton.EditorSearch search { get; private set; }

    public Editor(string? path, uint id)
    {
        this.id = id;
        this.is_modified = false;
        this.is_loading = false;

        this.build_ui();
        this.editor_apply_settings();
        this.add_completion_words();
        this.update_ui();

        if (path != null)
        {
            this.file = new Proton.File(path);
            this.open();
        }

        this.connect_signals();

        // TODO: Implement Proton.SourceGutterRenderer and insert it here
        // FIXME this is a terrible temporary solution to gutter padding
        var gt = this.sview.get_gutter(Gtk.TextWindowType.LEFT);
        var rend = gt.get_renderer_at_pos(5, 5);
        if (rend != null)
        {
            var ic_rend = new Gtk.SourceGutterRendererPixbuf();
            ic_rend.set_padding(5, -1);
            gt.insert(ic_rend, 0);
            gt.reorder(rend, 1);
            rend.set_padding(10, -1);
        }
    }

    private void build_ui()
    {
        this.sview = new Gtk.SourceView();
        this.buffer = this.sview.buffer as Gtk.SourceBuffer;
        this.search = new Proton.EditorSearch(this);

        this.highlight_tag = this.sview.buffer.create_tag(
            "highlight-tag",
            /* Null-terminated roperties */
            "background", "yellow",
            null
        );
        this.search_tag = this.sview.buffer.create_tag(
            "search-tag",
            /* Null-terminated roperties */
            "background", "yellow",
            null
        );

        this.sview.show();
    }

    private void connect_signals()
    {
        // Overscroll
        if (this._settings.scroll_over)
            this.connect_parent_set();

        // Text highlight
        this.buffer.notify["cursor-position"].connect(
            this.maybe_highlight_selected
        );

        // Text highlight
        this.buffer.notify["has-selection"].connect(
            this.maybe_highlight_selected
        );
    }

    private void connect_parent_set()
    {
        this.sview.parent_set.connect((previous_parent) => {
            // Prevent on window close critical error messages
            if (this.sview.parent == null && previous_parent != null)
                // if there is no parent now and there was a previous parent
                return ;

            // TODO: Check if font-size changes should also trigger this
            // this.sview.parent.size_allocate.connect(this.adjust_margin);
            this.sview.size_allocate.connect(this.adjust_margin);

            // TODO: The following commented code might actually be necessary
            // sview.event.connect((e) => {
            //     if (e.type == Gdk.EventType.VISIBILITY_NOTIFY)
            //         adjust_margin();
            //     return (false);
            // });
        });
    }

    private void maybe_highlight_selected()
    {
        Gtk.TextIter buf_siter, buf_eiter, sel_siter, sel_eiter;
        string       text;

        this.buffer.get_bounds(out buf_siter, out buf_eiter);
        this.buffer.remove_tag_by_name("highlight-tag",
                                       buf_siter,
                                       buf_eiter);

        if (!this.buffer.has_selection)
            return ;

        this.buffer.get_selection_bounds(out sel_siter, out sel_eiter);

        text = this.buffer.get_text(sel_siter, sel_eiter, false);
        if (text != "")
        {
            this.highlight_selected(text, buf_siter);
        }
    }

    private void highlight_selected(string text, Gtk.TextIter start)
    {
        Gtk.TextIter mstart, mend;

        if (start.forward_search(text, 0, out mstart, out mend, null))
        {
            this.buffer.apply_tag(this.highlight_tag, mstart, mend);
            this.highlight_selected(text, mend);
        }
    }

    // TODO make this optional
    private void add_completion_words()
    {
        var comp = new Gtk.SourceCompletionWords("Completion", null);

        comp.register(this.buffer);
        try
        {
            if (!this.sview.completion.add_provider(comp))
                warning("Could not add completion provider.");
        }
        catch (Error e) { warning(e.message); }
    }

    private int  previous_height = 0;
    private void adjust_margin(Gtk.Allocation alloc)
    {
        if (alloc.height == this.previous_height)
            return ;

        this.previous_height = alloc.height;

        if (this.line_height <= 0)
            return ;

        this.sview.bottom_margin =
            this.sview.parent.get_allocated_height() - this.line_height;
    }

    public void update_ui()
    {
        //
        // Setting the font
        {
            Pango.FontDescription   font_desc;
            string?                 family;
            string                  data;

            this.buffer.style_scheme =
                Gtk.SourceStyleSchemeManager.get_default()
                   .get_scheme(this._settings.style_id);

            font_desc = Pango.FontDescription.from_string(
                this._settings.font_family
            );
            family    = font_desc.get_family();

            if (family != null && family.index_of("None") == -1)
            {
                // Set the font family and size via css using Marble.Utils
                data = "textview { font-family: %s; font-size: %dpt; }".printf(
                    family, font_desc.get_size() / Pango.SCALE
                );

                Marble.set_theming_for_data(this.sview, data, null,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }
        }

        //
        // Setting the highlight_tag style
        {
            var scheme = this.buffer.style_scheme;
            var style  = scheme.get_style("search-match");

            if (style != null)
            {
                style.apply(this.highlight_tag);
                style.apply(this.search_tag);
            }
        }

        /*
         * Copyright 2015-2019 Christian Hergert <christian@hergert.me>
         *
         * The following code block is a derivative work of the code from
         * https://gitlab.gnome.org/GNOME/gnome-builder/ which is licensed under
         * the GNU General Public License as published by the Free Software
         * Foundation, either version 3 of the License, or any later version.
         *
         * SPDX-License-Identifier: GPL-3.0-or-later
         *
         * Based on: src/libide/sourceview/ide-source-view.c cached_char_height
         *
         * Updating this.line_height
         */
        {
            Pango.Context   ctx     = this.sview.get_pango_context();
            Pango.Layout    layout  = new Pango.Layout(ctx);

            layout.set_text("X", 1);
            layout.get_pixel_size(null, out this.line_height);
        }

        this.ui_modified();
    }

    // TODO use some actual settings
    private void editor_apply_settings()
    {
        this.sview.right_margin_position = 80;
        this.sview.set_auto_indent(true);
        this.sview.set_highlight_current_line(true);
        this.sview.set_indent_on_tab(true);
        this.sview.set_indent_width(4);
        this.sview.set_insert_spaces_instead_of_tabs(true);
        this.sview.set_left_margin(5);
        this.sview.set_monospace(true);
        this.sview.set_right_margin(5);
        this.sview.set_show_line_numbers(true);
        this.sview.set_show_right_margin(true);
        this.sview.set_smart_backspace(true);
        this.sview.set_smart_home_end(Gtk.SourceSmartHomeEndType.ALWAYS);
        this.sview.set_tab_width(4);
        this.sview.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);

        // TODO: implement this on settings
        // sview.background_pattern = Gtk.SourceBackgroundPatternType.GRID;

        this.sview.space_drawer.set_types_for_locations(
            Gtk.SourceSpaceLocationFlags.ALL, Gtk.SourceSpaceTypeFlags.NONE
        );

        // Space drawer configuration
        // TODO: implement this on settings
        {
            var type_flags     = Gtk.SourceSpaceTypeFlags.NONE;
            var location_flags = Gtk.SourceSpaceLocationFlags.NONE;

            type_flags |= Gtk.SourceSpaceTypeFlags.SPACE;
            type_flags |= Gtk.SourceSpaceTypeFlags.TAB;

            location_flags |= Gtk.SourceSpaceLocationFlags.TRAILING;

            this.sview.space_drawer.set_types_for_locations(
                location_flags, type_flags
            );

            this.sview.space_drawer.set_enable_matrix(true);
        }
    }

    public void set_language(Gtk.SourceLanguage? lang)
    {
        Gtk.SourceLanguageManager lm;

        this.language = lang;
        if (this.language == null && this.file != null)
        {
            lm = Gtk.SourceLanguageManager.get_default();
            this.language = lm.guess_language(this.file.name,
                                              this.file.content_type);
        }

        if (this.language != null && this.language.get_name() == "Makefile")
            this.sview.set_insert_spaces_instead_of_tabs(false);

        this.buffer.set_language(this.language);
    }

    private void open()
    {
        this.is_loading = true;
        this.file.read_async.begin(null, this.open_finished);
    }

    private void open_finished(GLib.Object? obj, GLib.AsyncResult res)
    {
        string text = file.read_async.end(res);

        this.buffer.begin_not_undoable_action();
        this.buffer.set_text(text);
        this.buffer.end_not_undoable_action();

        this.set_language(null);

        if (this.last_saved_content == null)
            this.buffer.modified_changed.connect(this.update_modified);

        this.last_saved_content = text;
        this.buffer.set_modified(false);

        this.is_loading = false;
        this.loading_finished();
    }

    private void update_modified()
    {
        bool current     = this.is_modified;
        this.is_modified = this.buffer.get_modified();

        if (current != this.is_modified)
            this.modified(this.is_modified);
    }

    public async bool save()
    {
        string  content;
        bool    saved;

        if (this.file == null)
        {
            // TODO: implement a save file dialog here
            return (false);
        }

        if (!this.is_modified || !this.get_real_modified())
            return (true);

        // If any this.before_save handlers return true, return true.
        if (this.before_save())
            return (true);

        content = this.get_text();
        saved   = yield this.file.write_async(content);

        if (saved)
        {
            this.last_saved_content = content;
            // Auto-fires this.modified()
            this.buffer.set_modified(false);
        }

        return (saved);
    }

    private bool get_real_modified()
    {
        bool is_mod = (this.last_saved_content != this.get_text());
        // Auto-fires this.modified()
        this.buffer.set_modified(is_mod);
        return (is_mod);
    }

    public string get_text()
    {
        Gtk.TextIter start, end;

        this.buffer.get_bounds(out start, out end);

        return (this.buffer.get_text(start, end, true));
    }

    public void remove_search_tags()
    {
        Gtk.TextIter buf_siter, buf_eiter;

        this.buffer.get_bounds(out buf_siter, out buf_eiter);
        this.buffer.remove_tag_by_name("search-tag", buf_siter, buf_eiter);
    }
}
