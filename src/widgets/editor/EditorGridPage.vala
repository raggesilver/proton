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
    public Editor    editor { get; protected set; }

    Gtk.ScrolledWindow  scrolled;

    public EditorGridPage(Editor _editor)
    {
        editor = _editor;

        scrolled = new Gtk.ScrolledWindow(null, null);
        /*
         * I have absolutely no idea how Gtk.PolicyType.EXTERNAL works but it
         * presented the best results in all tests cases for split views and
         * resizing
         */
        scrolled.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);

        title = editor.file.name;

        /*
         * Connecting signals
         */
        update_ui();
        editor.ui_modified.connect(update_ui);

        editor.modified.connect((m) => {
            title = editor.file.name + ((m) ? " •" : "");
        });

        editor.sview.focus_in_event.connect((e) => {
            focused();
            return (false);
        });

        scrolled.add(editor.sview);
        pack_start(scrolled, true, true, 0);
        show_all();
    }

    void update_ui()
    {
        var buff = editor.sview.buffer as Gtk.SourceBuffer;

        Gtk.SourceStyleScheme? scheme = null;
        Gtk.SourceStyle? __style = null;

        if (null == (scheme = buff.get_style_scheme()) ||
            null == (__style = scheme.get_style("text")))
        {
            bg = fg = null;
            return ;
        }

        string _bg, _fg;
        __style.get("background", out _bg, "foreground", out _fg);
        bg = _bg;
        fg = _fg;
    }

    public override void destroy()
    {
        editor.destroy();
        base.destroy();
    }
}
