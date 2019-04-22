/* EditorPage.vala
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

public class Proton.EditorPage : Proton.EditorGridPage
{
    Gtk.CssProvider? provider = null;
    public Editor    editor { get; protected set; }

    public EditorPage(Editor editor)
    {
        this.editor = editor;

        get_style_context().add_class("editor-panel");

        scrolled.add(editor.sview);
        title = editor.file.name;
        title_button.label = title;
        pop_title_button.label = title;

        editor.ui_modified.connect(update_ui);

        editor.modified.connect((m) => {
            title_button.label = editor.file.name + ((m) ? " •" : "");
        });

        editor.sview.focus_in_event.connect((e) => {
            page_focused();
            return (false);
        });

        update_ui();
        show_all();
    }

    public override void destroy()
    {
        editor.destroy();
        base.destroy();
    }

    void update_ui()
    {
        if (provider != null)
            Gtk.StyleContext.remove_provider_for_screen(
                Gdk.Screen.get_default(), provider);

        // bg = editor.sview.get_style().bg[2];

        var buff = editor.sview.buffer as Gtk.SourceBuffer;

        Gtk.SourceStyleScheme? scheme = null;
        Gtk.SourceStyle? __style = null;

        if ((scheme = buff.get_style_scheme()) == null ||
            (__style = scheme.get_style("text")) == null)
        {
            return ;
        }

        string bg;
        string fg;
        __style.get("background", out bg, "foreground", out fg);

        try
        {
            provider = new Gtk.CssProvider();

            provider.load_from_data("""
                .editor-panel .panel-header {
                    border-bottom: 1px solid darker(%s);
                }
                .editor-panel .panel-header,
                .editor-panel .panel-header > * {
                    background: %s;
                }
                .editor-panel .panel-header > * { color: %s; }
                .editor-panel .panel-header > button:hover,
                .editor-panel .panel-header > button:active,
                .editor-panel .panel-header > button:checked {
                    background: shade(%s, .9);
                }
            """.printf(bg, bg, fg, bg));

            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
        catch {}
    }
}
