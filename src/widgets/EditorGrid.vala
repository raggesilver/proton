/* EditorGrid.vala
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

[GtkTemplate (ui="/com/raggesilver/Proton/layouts/editor_stack.ui")]
public class Proton.EditorStack : Gtk.Stack
{
    List<string> history;

    [GtkChild]
    Gtk.Popover pop;

    [GtkChild]
    Gtk.Label pop_specific_label;

    [GtkChild]
    Gtk.Box pop_specific_box;

    [GtkChild]
    Gtk.Box pop_pages_box;

    internal EditorStack()
    {
        // add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        history = new List<string>();
        
        notify["visible-child-name"].connect(on_switched);
    }

    public new void add_named(GridPage w, string name)
    {
        history.prepend(name);
        pop_pages_box.pack_start(w.pop_pages_box_item, false, true, 0);

        w.destroy.connect(() => {
            history.remove_link(history.find_custom(name, strcmp));
            if (history.length() > 0)
                set_visible_child_name(history.nth(0).data);
        });

        // w.renamed.connect(() => {});

        w.title_button.set_popover(pop);

        base.add_named(w, name);
    }

    void on_switched()
    {
        if (get_visible_child_name() != "background")
        {
            var page = (GridPage) get_visible_child();
            pop_specific_label.label = page.title;
        }
    }
}

public class Proton.EditorGrid : Gtk.EventBox
{
    EditorStack[]     stacks = {};
    Dazzle.MultiPaned paned;

    EditorStack       current_stack;

    unowned Window    win;

    public EditorGrid(Window _win)
    {
        win = _win;

        var a = new SimpleAction("new_terminal", null);
        a.activate.connect(on_new_terminal);

        win.add_action(a);
        win.application.set_accels_for_action(
            "win.new_terminal", {"<Control><Shift>T"});

        a = new SimpleAction("open_file", VariantType.STRING);
        a.activate.connect((s) => {
            open_file(new File(s.get_string()));
        });

        win.add_action(a);

        paned = new Dazzle.MultiPaned();
        paned.show();
        add(new_stack());

        show();
    }

    public void on_new_terminal()
    {
        if (current_stack == null)
            new_stack();

        var p = new TerminalPage(win);
        current_stack.add_named(p, p.title);
        current_stack.set_visible_child(p);
    }

    // Add a column
    // public void split_vertically()
    // {
    //     if (first_direction == null)
    //     {
    //         first_direction = Gtk.Orientation.HORIZONTAL;
    //         set_orientation(first_direction);
    //     }

    //     new_stack();
    //     pack_start(current_stack, true, true, 0);
    // }

    EditorStack new_stack()
    {
        var s = new EditorStack();
        stacks += s;

        current_stack = s;
        return (s);
    }

    public void open_file(File f)
    {
        Editor? ed = win.manager.get_editor(f);

        if (ed == null)
        {
            ed = win.manager.open(f);
            var p = new EditorPage(ed);

            current_stack.add_named(p, ed.file.path);
            current_stack.set_visible_child_name(ed.file.path);
        }
        else
        {
            var page = ed.sview.get_parent().get_parent();
            (page.get_parent() as EditorStack).set_visible_child(page);
            // ed.sview.grab_focus();
        }
    }
}
