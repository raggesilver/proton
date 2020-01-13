/* EditorSearchBox.vala
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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/editor_search_box.ui")]
public class Proton.EditorSearchBox : Gtk.Box
{
    weak Gtk.SourceView   view;
    weak Gtk.SourceBuffer buff;
    weak Proton.Editor    editor;

    [GtkChild] Gtk.Image toggle_image;
    [GtkChild] Gtk.Label result_count_label;
    [GtkChild] Gtk.Revealer advanced_revealer;

    [GtkChild] public Gtk.Button close_button;
    [GtkChild] public Gtk.Entry search_entry;
    [GtkChild] public Gtk.Entry replace_entry;

    public bool show_advanced { get; set; default = false; }

    public EditorSearchBox(Proton.Editor editor)
    {
        this.editor = editor;
        this.view = editor.sview;
        this.buff = this.view.buffer as Gtk.SourceBuffer;

        this.notify["show-advanced"].connect(this.on_show_advanced_toggled);
        this.search_entry.notify["text"].connect(this.on_search_modified);

        editor.search.notify["current-result"].connect(this.update_result);
        editor.search.context.notify["occurrences-count"]
                             .connect(this.update_result);
    }

    [GtkCallback]
    private void on_advanced_toggled()
    {
        this.show_advanced = !this.show_advanced;
    }

    public void on_revealed(bool shown)
    {
        if (shown)
        {
            if (!this.maybe_get_selection())
                this.on_search_modified();
        }
        else
        {
            // On hide
            this.show_advanced = false; // Hide advanced on close
            this.editor.search.search(null);
        }
    }

    public void on_show_advanced_toggled()
    {
        this.advanced_revealer.set_reveal_child(this.show_advanced);

        this.toggle_image.set_from_icon_name(
            (this.show_advanced) ? "go-down-symbolic" : "go-next-symbolic",
            Gtk.IconSize.MENU
        );
    }

    private void on_search_modified()
    {
        this.editor.search.search(this.search_entry.get_text());
    }

    private void update_result()
    {
        int res = this.editor.search.context.occurrences_count;
        int cur = this.editor.search.current_result;
        var ctx = this.get_style_context();

        cur = (cur == -1) ? 0 : cur;

        if (res < 1)
        {
            this.result_count_label.label = "No results";
            ctx.add_class("no-results");
        }
        else
        {
            this.result_count_label.label = "%d of %d".printf(cur, res);
            ctx.remove_class("no-results");
        }
    }

    [GtkCallback]
    private void on_next()
    {
        this.editor.search.next.begin((obj, res) => {
            Gtk.TextIter s, e;

            if (this.editor.search.next.end(res, out s, out e))
            {
                this.editor.buffer.select_range(e, s);
                this.editor.sview.scroll_to_iter(s, 0, true, 0.5, 0.5);
            }
        });
    }

    [GtkCallback]
    private void on_previous()
    {
        this.editor.search.prev.begin((obj, res) => {
            Gtk.TextIter s, e;

            if (this.editor.search.prev.end(res, out s, out e))
            {
                this.editor.buffer.select_range(e, s);
                this.editor.sview.scroll_to_iter(s, 0, true, 0.5, 0.5);
            }
        });
    }

    [GtkCallback]
    private void do_replace_one()
    {
        if (this.on_before_replace())
            return ;

        string s = this.replace_entry.get_text();

        if (this.editor.search.replace(s))
            this.on_next();

        this.editor.search.update_current_result();
    }

    [GtkCallback]
    private void do_replace_all()
    {
        if (this.on_before_replace())
            return ;

        string s = this.replace_entry.get_text();

        this.editor.search.replace_all(s);
    }

    // If user requests a replace but there is no text selected, run next and
    // cancel the text replacement
    private bool on_before_replace()
    {
        if (this.editor.buffer.has_selection)
            return (false);

        if (this.editor.search.context.occurrences_count > 0)
            this.on_next();

        return (true);
    }

    // If the user `Ctrl+F`s with text selected, use that text as search
    private bool maybe_get_selection()
    {
        Gtk.TextIter s = {};
        Gtk.TextIter e = {};

        if (this.editor.buffer.has_selection &&
            this.editor.buffer.get_selection_bounds(out s, out e))
        {
            this.search_entry.set_text(
                this.editor.buffer.get_text(s, e, false)
            );
            return (true);
        }

        return (false);
    }
}
