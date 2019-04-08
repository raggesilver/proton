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

public class Proton.Command
{
    public signal void show_page();

    protected weak Window win;

    public string g;
    public string c;
    public string? icon_name;
    public CommandCallback cb;

    public Gtk.Widget? page = null;

    public Command(Window _win,
                   string group,
                   string command,
                   string? icon,
                   owned CommandCallback callback)
    {
        win = _win;
        g = group;
        c = command;
        icon_name = icon;
        cb = (owned) callback;
    }
}

public class Proton.EntryCommand : Proton.Command
{
    public Gtk.Entry entry { get; protected set; }

    public EntryCommand(Window _win,
                        string group,
                        string command,
                        string? icon)
    {
        entry = new Gtk.Entry();

        page = entry as Gtk.Widget;

        base(_win, group, command, icon, () => {
            show_page();
        });
    }
}

public class Proton.CommandPalette : Object
{
    weak Window    win;
    Gtk.Entry      entry;
    Array<Command> commands;
    // Gtk.ListStore  store;
    Gtk.Box        palette;
    Gtk.Stack      stack;

    enum CompletionMode {
        COMMAND,
        FILE
    }

    // CompletionMode completion_mode;

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

    public bool add_command(Command command)
    {
        if (command.page != null)
        {
            // Add page to stack and connect signal
            stack.add_named(command.page, @"$(command.g)$(command.c)");
            command.show_page.connect(() => {
                stack.set_visible_child(command.page);
            });
        }
        commands.append_val(command);
        repopulate_completion();
        return (true);
    }

    void do_show()
    {
        palette.show();
        entry.grab_focus();
        stack.set_visible_child_name("main");
    }

    bool do_show_command()
    {
        do_show();
        entry.set_text(">");
        entry.set_position(1);
        return (false);
    }

    void repopulate_completion()
    {

    }

    void build_ui()
    {
        var b = new Gtk.Builder.from_resource(
            "/com/raggesilver/Proton/layouts/command_palette.ui");
        palette = (Gtk.Box) b.get_object("box");
        entry = (Gtk.Entry) b.get_object("entry");
        stack = (Gtk.Stack) b.get_object("stack");
        var ev = (Gtk.EventBox) b.get_object("ev");

        ev.button_press_event.connect((e) => {
            if (e.type == Gdk.EventType.BUTTON_PRESS)
                palette.hide();
            return (false);
        });

        ev.key_press_event.connect((e) => {
            if (e.keyval == Gdk.Key.Escape)
                palette.hide();
            if (e.keyval == Gdk.Key.Alt_L)
                palette.hide();
            return (false);
        });

        win.overlay.add_overlay(palette);
        win.overlay.set_overlay_pass_through(palette, true);
    }
}
