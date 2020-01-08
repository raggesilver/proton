/* IdeGrid.vala
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

public class Proton.IdeGrid : Gtk.EventBox
{
    MultiPaned          paned;
    List<IdeGridStack>  stacks = new List<IdeGridStack>();
    IdeGridStack        current_stack;
    weak Window         window;

    public IdeGrid(Window _win)
    {
        window = _win;
        paned = new MultiPaned(Gtk.Orientation.HORIZONTAL);
        paned.show();

        add(paned);

        current_stack = new_stack();
        paned.add(current_stack);
        current_stack.show();

        /*
        ** Create the actions handled by IdeGrid
        */

        var a = new SimpleAction("open_file", VariantType.STRING);
        a.activate.connect((s) => {
            open_file(new File(s.get_string()));
        });

        window.add_action(a);

        a = new SimpleAction("split_vertical", null);
        a.activate.connect(split_vertical);

        window.add_action(a);

        a = new SimpleAction("new_terminal", null);
        a.activate.connect(new_terminal);

        window.add_action(a);
        window.application.set_accels_for_action(
            "win.new_terminal", {"<Control><Shift>T"});

        a = new SimpleAction("close_page", null);
        a.activate.connect(close_page);

        window.add_action(a);
        window.application.set_accels_for_action(
            "win.close_page", {"<Control>W"});
    }

    IdeGridStack new_stack()
    {
        var s = new IdeGridStack();

        s.close.connect(() => {
            return (stacks.length() > 1);
        });

        s.focused.connect(() => {
            current_stack = s;
        });

        s.destroy.connect(() => {
            stacks.remove(s);
            if (stacks.length() > 0)
                current_stack = stacks.last().data;
        });

        stacks.append(s);
        return (s);
    }

    public void split_vertical()
    {
        var s = new_stack();
        paned.add(s);
        current_stack = s;
    }

    public void open_file(File f)
    {
        Editor? ed = window.manager.get_editor(f);

        if (ed == null)
        {
            ed = window.manager.open(f);
            var p = new EditorGridPage(ed);

            current_stack.add_page(p);
        }
        else
        {
            // EditorGridPage detects sview.focus and asks it's current
            // IdeGridStack to be the visible child. Fixes #27 #31
            ed.sview.grab_focus();
        }
    }

    public void new_terminal()
    {
        var t = new TerminalGridPage(window);
        current_stack.add_page(t);
    }

    public void close_page()
    {
        current_stack.close_page();
    }
}
