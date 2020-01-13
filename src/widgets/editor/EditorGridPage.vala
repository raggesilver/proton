/* EditorGridPage.vala
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

public class Proton.EditorGridPage : Proton.IdeGridPage
{
    public  Editor              editor   { get; protected set; }

    private Gtk.ScrolledWindow  scrolled;
    private Marble.Progressable progressable;
    private Gtk.Revealer        revealer;
    private EditorSearchBox     search_box;
    private Gtk.Overlay         overlay;

    public EditorGridPage(Editor editor)
    {
        this.editor       = editor;
        this.scrolled     = new Gtk.ScrolledWindow(null, null);
        this.progressable = new Marble.Progressable();
        this.search_box   = new EditorSearchBox(editor);
        this.revealer     = new Gtk.Revealer();
        this.overlay      = new Gtk.Overlay();

        /*
         * I have absolutely no idea how Gtk.PolicyType.EXTERNAL works but it
         * presented the best results in all tests cases for split views and
         * resizing
         */
        this.scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
                                 Gtk.PolicyType.AUTOMATIC);

        this.overlay.show();

        this.revealer.set_transition_type(
            Gtk.RevealerTransitionType.SLIDE_DOWN);
        this.revealer.set_transition_duration(200);
        this.revealer.halign = Gtk.Align.END;
        this.revealer.valign = Gtk.Align.START;

        this.revealer.add(this.search_box);
        this.revealer.show();
        this.revealer.set_reveal_child(false);

        this.overlay.add_overlay(this.revealer);

        this.title = this.editor.file.name;

        this.update_ui();
        this.connect_signals();

        this.scrolled.add(this.editor.sview);
        this.progressable.add(this.scrolled);
        this.overlay.add(this.progressable);

        this.pack_start(this.overlay, true, true, 0);

        this.scrolled.show();
        this.progressable.show();
        this.progressable.pulse();

        this.progressable.loading = this.editor.is_loading;
    }

    private void connect_signals()
    {
        this.editor.ui_modified.connect(this.update_ui);

        this.editor.modified.connect((m) => {
            this.title = this.editor.file.name + ((m) ? " •" : "");
        });

        this.editor.sview.focus_in_event.connect((e) => {
            this.focused(); // Proton.IdeGridPage.focused signal
            return (false);
        });

        this.editor.loading_finished.connect(() => {
            debug("is-loading: %s", this.editor.is_loading.to_string());
            this.progressable.loading = this.editor.is_loading;
        });

        this.key_press_event.connect((e) => {
            if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0)
            {
                switch (Gdk.keyval_name(e.keyval))
                {
                    case "f": this.on_ctrl_f(); return (true);
                    case "h": this.on_ctrl_h(); return (true);
                }
            }
            else if (Gdk.keyval_name(e.keyval) == "Escape" &&
                     this.revealer.reveal_child)
            {
                this.revealer.set_reveal_child(false);
                return (true);
            }
            return (false);
        });

        this.search_box.close_button.clicked.connect(() => {
            this.revealer.set_reveal_child(false);
        });

        this.revealer.notify["reveal-child"].connect(() => {
            this.search_box.on_revealed(this.revealer.reveal_child);

            // Focus editor on search closed
            if (this.revealer.reveal_child == false)
                this.editor.sview.grab_focus();
        });
    }

    // Simple search
    private void on_ctrl_f()
    {
        this.revealer.set_reveal_child(true);
        this.search_box.search_entry.grab_focus();
    }

    // Advanced search
    private void on_ctrl_h()
    {
        this.revealer.set_reveal_child(true);
        this.search_box.show_advanced = true;

        if (this.search_box.replace_entry.has_focus)
            this.search_box.search_entry.grab_focus();
        else
            this.search_box.replace_entry.grab_focus();
    }

    void update_ui()
    {
        var buff = this.editor.sview.buffer as Gtk.SourceBuffer;

        Gtk.SourceStyleScheme? scheme = null;
        Gtk.SourceStyle?       style  = null;

        if (null == (scheme = buff.get_style_scheme()) ||
            null == (style = scheme.get_style("text")))
        {
            bg = fg = null;
            return ;
        }

        string _bg, _fg;
        style.get("background", out _bg, "foreground", out _fg);
        bg = _bg;
        fg = _fg;
    }

    public override void destroy()
    {
        editor.destroy();
        base.destroy();
    }
}
