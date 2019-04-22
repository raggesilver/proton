/* TerminalPage.vala
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

public class Proton.TerminalPage : Proton.EditorGridPage
{
    public Terminal terminal { get; protected set; }

    unowned Window win;
    public TerminalPage(Window _win)
    {
        win = _win;

        terminal = new Terminal(win);
        scrolled.add(terminal);

        title = "terminal-%u".printf(terminal.id);
        title_button.label = title;

        pop_title_button.label = title;

        terminal.window_title_changed.connect(() => {
            title_button.label = terminal.window_title;
        });

        terminal.focus_in_event.connect((e) => {
            page_focused();
            return (false);
        });
    }
}
