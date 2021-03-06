/* BottomPanel.vala
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

public class Proton.BottomPanelTab : Object
{
    public signal void focus_tab();

    public Gtk.Widget content;
    public Gtk.Widget? aux_content;

    public bool enabled = true;
    public string name;
    public string title;
}

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/bottom_panel.ui")]
public class Proton.BottomPanel : Gtk.Box
{
    [GtkChild] Gtk.Stack stack;
    [GtkChild] Gtk.Stack aux_stack;

    private Window win;

    public BottomPanel(Window _win)
    {
        this.win = _win;

        this.stack.notify["visible-child-name"].connect(this.on_switched);
    }

    public bool add_tab(BottomPanelTab tab)
    {
        if (stack.get_child_by_name(tab.name) == null)
        {
            stack.add_titled(tab.content, tab.name, tab.title);

            tab.focus_tab.connect(() => {
                stack.set_visible_child(tab.content);
            });

            if (tab.aux_content != null)
                aux_stack.add_titled(tab.aux_content, tab.name, tab.title);

            return (true);
        }
        warning("A tab with named %s alread exists", tab.name);
        return (false);
    }

    void on_switched()
    {
        string? stack_vc = stack.visible_child_name;
        var _child = (stack_vc != null) ?
            this.aux_stack.get_child_by_name(stack_vc) : null;

        if (_child != null)
            aux_stack.set_visible_child(_child);
        else
            aux_stack.set_visible_child_name("empty");
    }
}
