/* TerminalTab.vala
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

public class Proton.TerminalTab : Proton.BottomPanelTab
{
    unowned Window   win;

    Array<Terminal?> terminals;
    Gtk.ListStore    store;

    Gtk.Stack        stack;
    Gtk.ComboBox     combo;
    Gtk.Box          box;
    Gtk.Button       new_terminal_button;
    Gtk.Button       delete_terminal_button;

    public TerminalTab(Window _win)
    {
        name  = "terminal-tab";
        title = "TERMINAL";

        win = _win;
        terminals = new Array<Terminal?>();

        stack = new Gtk.Stack();
        store = new Gtk.ListStore(2, typeof(string), typeof(string));
        combo = new Gtk.ComboBox.with_model(store);

        combo.set_entry_text_column(1);
        combo.set_id_column(0);

        combo.changed.connect(on_changed);

        var renderer = new Gtk.CellRendererText();
        combo.pack_start(renderer, true);
        combo.add_attribute(renderer, "text", 1);

        box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        new_terminal_button = new Gtk.Button.from_icon_name("list-add-symbolic",
                                                            Gtk.IconSize.MENU);

        new_terminal_button.clicked.connect(() => { add_terminal(); });
        new_terminal_button.set_relief(Gtk.ReliefStyle.NONE);

        delete_terminal_button = new Gtk.Button.from_icon_name(
                                        "user-trash-symbolic",
                                        Gtk.IconSize.MENU);

        delete_terminal_button.clicked.connect(() => { delete_current_terminal(); });
        delete_terminal_button.set_relief(Gtk.ReliefStyle.NONE);

        box.pack_start(delete_terminal_button, false, true, 0);
        box.pack_start(new_terminal_button, false, true, 0);
        box.pack_end(combo, false, true, 0);

        stack.show();
        box.show_all();

        content = stack;
        aux_content = box;

        add_terminal();
    }

    public Terminal add_terminal(string? command = null,
                                 bool self_destroy = false)
    {
        var term = new Terminal(win, command, self_destroy);
        terminals.append_val(term);

        uint id = terminals.length;
        string sid = id.to_string();

        term.child_exited.connect(() => {
            delete_terminal(sid);
        });

        stack.add_named(terminals.index(id - 1), sid);

        Gtk.TreeIter it;
        store.append(out it);

        store.set(it,
                  0, sid,
                  1, @"$id: $(term.window_title)");

        term.window_title_changed.connect(() => {
            store.set(it, 1, @"$id: $(term.window_title)");
        });

        combo.set_active_id(sid);
        return (term);
    }

    void on_changed()
    {
        stack.set_visible_child_name(combo.active_id);
    }

    void delete_current_terminal()
    {
        var sid = combo.active_id;
        delete_terminal(sid);
    }

    public void delete_terminal(string sid, bool no_create = false)
    {
        var id = int.parse(sid) - 1;
        var term = terminals.index(id);

        if (term == null)
            return ;

        Gtk.TreeIter it;

        if (combo.get_active_iter(out it))
            store.remove(ref it);

        term.destroy();
        terminals.data[id] = null;

        if (stack.get_children().length() == 0 && !no_create)
            add_terminal();
        else
            combo.set_active_id(stack.get_visible_child_name());
    }
}
