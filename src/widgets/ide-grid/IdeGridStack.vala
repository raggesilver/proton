/* IdeGridStack.vala
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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/proton_grid_stack.ui")]
public class Proton.IdeGridStack : Gtk.Box
{
    /*
     * This signal is emitted when a stack is about to destroy itself. IdeGrid
     * will return false if this is the last IdeGridStack (preventing this from
     * closging).
     */
    public signal bool close();
    public signal void focused();

    [GtkChild]
    public Gtk.Box      titlebar { get; private set; }
    [GtkChild]
    public Gtk.Stack    stack { get; private set; }
    [GtkChild]
    public Gtk.ListBox  pop_entry_box { get; private set; }
    [GtkChild]
    public Gtk.Popover  popover { get; private set; }
    [GtkChild]
    Gtk.Label           title_label;
    [GtkChild]
    Gtk.EventBox        background_event_box;

    ulong?              style_changed_handler = null;
    Gtk.CssProvider?    provider = null;


    List<IdeGridPage>   pages = new List<IdeGridPage>();
    // HashTable<IdeGridPage, Gtk.Widget> pop_entries;

    public IdeGridStack()
    {
        stack.notify["visible-child"].connect((c) => {
            if (stack.visible_child != background_event_box)
            {
                var p = stack.visible_child as IdeGridPage;
                title_label.label = p.title;

                /*
                ** This adds history behavior to closing pages.
                */
                pages.remove(p);
                pages.append(p);

                if (style_changed_handler != null)
                {
                    disconnect(style_changed_handler);
                    style_changed_handler = null;
                }

                style_changed_handler = p.style_changed.connect(() => {
                    if (p.bg != null && p.fg != null)
                        set_titlebar_style(p);
                    else
                        reset_titlebar_style();
                });

                if (p.bg != null && p.fg != null)
                    set_titlebar_style(p);
                else
                    reset_titlebar_style();
            }
            else
                title_label.label = "";
        });

        titlebar.button_release_event.connect(() => {
            focused();
            return (false);
        });

        background_event_box.button_press_event.connect(() => {
            focused();
            return (false);
        });
    }

    public void add_page(IdeGridPage page)
    {
        pages.append(page);

        page.show_all();

        pop_entry_box.insert(page.pop_entry, -1);

        page.focused.connect(() => {
            focused();
        });

        page.destroy.connect(() => {
            pages.remove(page);
            if (pages.length() > 0)
            {
                reset_titlebar_style();
                stack.set_visible_child(pages.last().data);
            }
            else if (close())
                destroy();
            else
                reset_titlebar_style();
        });

        stack.add(page);
        stack.set_visible_child(page);
    }

    public void close_page()
    {
        var c = stack.get_visible_child();
        if (c != background_event_box)
            c.destroy();
    }

    void reset_titlebar_style()
    {
        if (provider != null)
        {
            foreach (var c in titlebar.get_children())
                c.get_style_context().remove_provider(provider);
            titlebar.get_style_context().remove_provider(provider);
        }
        provider = null;
    }

    void set_titlebar_style(IdeGridPage page)
    {
        if (page != stack.get_visible_child())
            return;

        if (provider != null)
        {
            foreach (var c in titlebar.get_children())
                c.get_style_context().remove_provider(provider);
            titlebar.get_style_context().remove_provider(provider);
        }

        provider = new Gtk.CssProvider();
        provider.load_from_data("""
        .panel-header {
            border-bottom: 1px solid darker(%s);
        }
        .panel-header,
        .panel-header > * {
            background: %s;
        }
        .panel-header > * { color: %s; }
        .panel-header > button:hover,
        .panel-header > button:active,
        .panel-header > button:checked {
            background: shade(%s, .9);
        }
        """.printf(page.bg, page.bg, page.fg, page.bg));

        titlebar.get_style_context().add_provider(
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        foreach (var c in titlebar.get_children())
            c.get_style_context().add_provider(
                provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    [GtkCallback]
    void on_pop_entry_row_activated(Gtk.ListBoxRow _r)
    {
        stack.set_visible_child((_r as IdeGridPagePopEntry).page);
        popover.popdown();
    }

    [GtkCallback]
    void on_close_button_clicked()
    {
        if (pages.length() != 0)
            (stack.get_visible_child() as IdeGridPage).destroy();
        else if (close())
            destroy();
    }
}
