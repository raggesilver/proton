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
    private weak Window window;

    private Array<Terminal?>    terminals;
    private Gtk.ListStore       store;
    private Gtk.Stack           stack;
    private Gtk.ComboBox        combo;
    private Gtk.Box             box;
    private Gtk.Button          new_terminal_button;
    private Gtk.Button          delete_terminal_button;
    private bool                is_destroying = false;

    public TerminalTab(Window window)
    {
        this.window = window;

        // Proton.BottomPanelTab properties
        this.name  = "terminal-tab";
        this.title = "TERMINAL";

        this.terminals = new Array<Terminal?>();
        this.stack     = new Gtk.Stack();
        this.store     = new Gtk.ListStore(2, typeof(string), typeof(string));
        this.combo     = new Gtk.ComboBox.with_model(this.store);
        this.box       = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);

        this.new_terminal_button = new Gtk.Button.from_icon_name(
            "list-add-symbolic", Gtk.IconSize.MENU);
        this.new_terminal_button.set_relief(Gtk.ReliefStyle.NONE);
        this.new_terminal_button.clicked.connect(() => {
            this.add_terminal();
        });

        this.delete_terminal_button = new Gtk.Button.from_icon_name(
            "user-trash-symbolic", Gtk.IconSize.MENU);
        this.delete_terminal_button.set_relief(Gtk.ReliefStyle.NONE);
        this.delete_terminal_button.clicked.connect(() => {
            this.delete_terminal(this.combo.active_id);
        });


        this.build_combo();

        this.box.pack_start(this.delete_terminal_button, false, true, 0);
        this.box.pack_start(this.new_terminal_button, false, true, 0);
        this.box.pack_end(this.combo, false, true, 0);

        this.stack.show();
        this.box.show_all();

        // Proton.BottomPanelTab properties
        this.content = this.stack;
        this.aux_content = this.box;
    }

    private void build_combo()
    {
        this.combo.set_id_column(0);
        this.combo.set_entry_text_column(1);

        var renderer = new Gtk.CellRendererText();
        this.combo.pack_start(renderer, true);
        this.combo.add_attribute(renderer, "text", 1);

        this.combo.changed.connect(this.on_combo_changed);
        this.combo.destroy.connect(() => {
            this.is_destroying = true;
        });
    }

    private void on_combo_changed()
    {
        string? active_id = this.combo.active_id;
        if (active_id != null)
        {
            stack.set_visible_child(
                this.terminals.index(int.parse(active_id))
            );
        }
    }

    private void delete_terminal(string? sid)
    {
        if (sid == null)
            return ;

        int          id   = int.parse(sid);
        Terminal?    term = this.terminals.index(id);
        Gtk.TreeIter iter;

        if (term == null)
            return ;

        if (this.combo.get_active_iter(out iter))
        {
            this.store.remove(ref iter);
        }

        this.terminals.data[id] = null;
        term.destroy();

        if (this.stack.get_children().length() != 0)
        {
            this.combo.set_active_id(
                this.stack.get_visible_child_name()
            );
        }
        else if (!this.is_destroying)
        {
            this.add_terminal();
        }
    }

    public Terminal add_terminal(string? command      = null,
                                 bool    self_destroy = false)
    {
        var          term = new Terminal(this.window, command, self_destroy);
        Gtk.TreeIter it;
        string       sid = this.terminals.length.to_string();

        this.terminals.append_val(term);

        term.child_exited.connect(() => {
            this.delete_terminal(sid);
        });

        this.stack.add_named(term, sid);

        this.store.append(out it);
        this.store.set(it,
            0, sid,
            1, @"$sid: $(term.window_title)");

        term.window_title_changed.connect(() => {
            this.store.set(it, 1, @"$sid: $(term.window_title)");
        });

        this.combo.set_active_id(sid);
        return (term);
    }
}
