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

    [GtkChild] public Gtk.Box titlebar { get; private set; }
    [GtkChild] public Gtk.ListBox pop_entry_box { get; private set; }
    [GtkChild] public Gtk.MenuButton title_button { get; private set; }
    [GtkChild] public Gtk.Popover popover { get; private set; }
    [GtkChild] public Gtk.Stack stack { get; private set; }

    [GtkChild] Gtk.EventBox background_event_box;
    [GtkChild] Gtk.EventBox titlebar_eb;
    [GtkChild] Gtk.Label title_label;

    private Gtk.CssProvider? provider = null;
    private Gtk.Widget? prev_page = null;
    private List<IdeGridPage> pages = new List<IdeGridPage>();
    private ulong[] handlers = { 0, 0 };

    public IdeGridStack()
    {
        this.connect_signals();
    }

    private void connect_signals()
    {
        this.stack.notify["visible-child"].connect(this.on_child_changed);

        this.titlebar_eb.button_release_event.connect((e) => {
            if (e.button == 2)
            {
                this.on_close_button_clicked();
                return (true);
            }
            return (false);
        });

        this.background_event_box.button_press_event.connect(() => {
            this.focused();
            return (false);
        });
    }

    private void on_child_changed()
    {
        IdeGridPage page;

        if (this.prev_page != null)
        {
            foreach (ulong h in this.handlers)
                if (h > 0)
                    this.prev_page.disconnect(h);
            this.prev_page = null;
        }

        if (this.stack.visible_child == this.background_event_box)
        {
            this.title_label.label = "";
            return;
        }

        page = this.stack.visible_child as IdeGridPage;
        this.title_label.label = page.title;

        // History behavior
        this.pages.remove(page);
        this.pages.append(page);

        this.handlers[0] = page.style_changed.connect(() => {
            if (page.bg != null && page.fg != null)
                this.set_titlebar_style(page);
            else
                this.reset_titlebar_style();
        });

        this.handlers[1] = page.notify["title"].connect(() => {
            this.title_label.label = page.title;
        });

        if (page.bg != null && page.fg != null)
            this.set_titlebar_style(page);
        else
            this.reset_titlebar_style();
    }

    public void add_page(IdeGridPage page)
    {
        pages.append(page);

        page.show();

        pop_entry_box.insert(page.pop_entry, -1);

        page.focused.connect(() => {
            this.focused();
            // Workaround for #27
            if (this.stack.get_visible_child() != page)
                this.stack.set_visible_child(page);
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

        try
        {
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
        catch (Error e) { warning(e.message); }
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

    [GtkCallback]
    void on_new_terminal_button_clicked()
    {
        this.focused();
    }
}
