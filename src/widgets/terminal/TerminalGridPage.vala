/* TerminalGridPage.vala
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

public class Proton.TerminalGridPage : IdeGridPage
{
    public  Terminal    terminal { get; protected set; }
    unowned Window      win;

    public TerminalGridPage(Window _win)
    {
        win = _win;

        terminal = new Terminal(win);
        var scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
        scrolled.add(terminal);

        pack_start(scrolled, true, true, 0);
        show_all();

        title = "Terminal %u".printf(terminal.id);

        // FIXME: create a way to change the title only on IdeGridStack.titlebar
        // and keep the initial on IdeGridStack.popover

        // terminal.window_title_changed.connect(() => {
        //     title = terminal.window_title;
        // });

        terminal.focus_in_event.connect((e) => {
            focused();
            return (false);
        });

        terminal.child_exited.connect((status) => {
            this.destroy();
        });
    }
}
