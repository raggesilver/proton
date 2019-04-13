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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/editor_page.ui")]
public class Proton.EditorPage : Gtk.Box
{
    [GtkChild]
    Gtk.Button file_button;

    [GtkChild]
    Gtk.ScrolledWindow scrolled;
    
    [GtkChild]
    Gtk.Box header;
    
    [GtkChild]
    Gtk.Button close_button;
    
    [GtkChild]
    Gtk.Label filename_label;

    Gtk.CssProvider? provider = null;
    Editor           editor;

    public EditorPage(Editor editor)
    {
        this.editor = editor;

        scrolled.add(editor.sview);
        file_button.label = editor.file.name;
        filename_label.label = editor.file.name;

        editor.ui_modified.connect(update_ui);
        
        editor.modified.connect((m) => {
            file_button.label = editor.file.name + ((m) ? " •" : "");
        });
        
        close_button.clicked.connect(() => {
            destroy();
        });

        update_ui();
    }
    
    public override void destroy()
    {
        editor.destroy();
        base.destroy();
    }

    void update_ui()
    {
        var ctx = header.get_style_context();
        
        if (provider != null)
            ctx.remove_provider_for_screen(ctx.screen, provider);

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
        
        provider = new Gtk.CssProvider();
        
        provider.load_from_data("""
            .panel-header, .panel-header > * { background: %s; }
            .panel-header > * { color: %s; }
            .panel-header > button:hover,
            .panel-header > button:active,
            .panel-header > button:checked { background: shade(%s, .9); }
        """.printf(bg, fg, bg));
            
        ctx.add_provider_for_screen(
            ctx.screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}
