/* CommandPalette.vala
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

namespace Proton
{
    public delegate void CommandCallback();
}

class Proton.Command
{
    public string g;
    public string c;
    public string? icon_name;
    public bool m;
    public CommandCallback cb;

    public Command(string group,
                   string command,
                   string? icon,
                   CommandCallback callback,
                   bool multiple = false)
    {
        g = group;
        c = command;
        icon_name = icon;
        m = multiple;
        cb = callback;
    }
}

public class Proton.CommandPalette : Object
{
    weak Window    win;
    Gtk.Entry      entry;
    Array<Command> commands;
    Gtk.ListStore  store;
    Gtk.Window     palette;

    enum CompletionMode {
        COMMAND,
        FILE
    }

    CompletionMode completion_mode;

    public CommandPalette(Window _win)
    {
        commands = new Array<Command>();
        win = _win;

        build_ui();

        win.accel_group.connect(Gdk.keyval_from_name ("p"),
                                Gdk.ModifierType.CONTROL_MASK |
                                    Gdk.ModifierType.SHIFT_MASK,
                                0,
                                do_show_command);
    }

    public bool add_command(string group, string command, CommandCallback cb)
    {
        commands.append_val(new Command(group, command, null, cb));
        repopulate_completion();
        return (true);
    }

    void reset(string? text = "")
    {
        entry.set_text(text);
        entry.set_position(text.length);
    }

    bool do_show_command()
    {
        if (palette.get_visible())
            palette.hide();
        else
        {
            palette.show();
            palette.grab_focus();
            entry.grab_focus();
            reset(">");
        }
        return (false);
    }

    void build_ui()
    {
        var builder = new Gtk.Builder.from_resource(
            "/com/raggesilver/Proton/layouts/command_palette.ui");
        palette = (builder.get_object("dialog")) as Gtk.Window;

        entry   = (builder.get_object("entry")) as Gtk.Entry;
        var completion = new Gtk.EntryCompletion();
        store = new Gtk.ListStore(1, typeof(string));
        entry.completion = completion;
        entry.completion.set_text_column(0);

        palette.set_events(Gdk.EventMask.FOCUS_CHANGE_MASK);
        win.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);

        win.button_press_event.connect((e) => {
            // print("Pressed\n");
            return (false);
        });

        palette.focus_out_event.connect((e) => {
            palette.hide();
            return (true);
        });

        palette.set_transient_for(win);

        // completion_mode = CompletionMode.COMMAND;
        // complete_command();
    }

    void on_changed()
    {
        string s = entry.get_text();
        if (s[0] == '>' && (s = s.offset(1)) != null && s.length != 0 &&
            completion_mode != CompletionMode.COMMAND)
            complete_command();
    }

    void repopulate_completion()
    {
        complete_command();
    }

    void complete_command()
    {
        store.clear();

        Gtk.TreeIter it;
        for (var i = 0; i < commands.length; i++)
        {
            store.append(out it);
            store.set_value(it, 0, ">" + commands.index(i).c);
            print("Appended >%s\n", commands.index(i).c);
        }

        entry.completion.set_match_func(command_match);
    }

    bool command_match(Gtk.EntryCompletion c, string k, Gtk.TreeIter it)
    {
        for (var i = 0; i < commands.length; i++)
        {
            if (commands.index(i).c.index_of(k.offset(1)) != -1)
                return (true);
        }
        return (false);
    }
}
