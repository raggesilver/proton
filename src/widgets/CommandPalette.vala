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

class Proton.CompletionListRow : Gtk.ListBoxRow
{
    public string text { get; protected set; }

    public CompletionListRow(string _text, string? markup = null)
    {
        text = _text;

        var l = new Gtk.Label(null);
        l.xalign = 0;
        l.set_ellipsize(Pango.EllipsizeMode.START);
        l.margin = 5;

        l.set_markup((markup != null) ? markup : text);

        add(l);
        show_all();

        can_focus = false;
    }
}

public class Proton.CommandPalette : Object
{
    weak Window    win;
    Gtk.Entry      entry;
    Array<Command> commands;
    Gtk.Box        palette;
    Gtk.Stack      stack;
    Gtk.ListBox    completion_list;

    const string find_command = "find '%s' -type f -name '*%s*'";

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
        win.accel_group.connect(Gdk.keyval_from_name ("p"),
                                Gdk.ModifierType.CONTROL_MASK,
                                0,
                                do_show_files);
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

    bool do_show_files()
    {
        completion_mode = CompletionMode.FILE;
        do_show();
        entry.set_text("");
        entry.set_position(0);
        return (false);
    }

    bool do_show_command()
    {
        completion_mode = CompletionMode.COMMAND;
        do_show();
        entry.set_text(">");
        entry.set_position(1);
        return (false);
    }

    void repopulate_completion()
    {
    }

    void do_completion()
    {
        completion_list.forall((w) => {
            w.destroy();
        });

        string s = entry.get_text();

        if (s.has_prefix(">"))
        {
            completion_mode = CompletionMode.COMMAND;
            do_command_completion.begin();
        }
        else
        {
            completion_mode = CompletionMode.FILE;
            do_file_completion.begin();
        }
    }

    async void do_command_completion()
    {

    }

    async void do_file_completion()
    {
        SourceFunc callback = do_file_completion.callback;

        new Thread<bool>("complete_files_thread", () => {

            t_do_file_completion.begin((_, res) => {
                Idle.add((owned) callback);
            });

            return (true);
        });

        yield;
    }

    async void t_do_file_completion()
    {
        var text = entry.get_text();

        if (text == "")
            return ;

        string[] matches = {};
        string sout = "";
        string f = find_command.printf(win.root.path, text);

        if (Process.spawn_command_line_sync(
            f, out sout))
        {
            matches = sout.split("\n");
        }

        int max = (matches.length > 10) ? 10 : matches.length;
        for (int i = 0; i < max; i++)
        {
            string s = matches[i];
            if (s == "")
                continue ;

            var r = new CompletionListRow(s,
                s.offset(win.root.path.length + 1)
                 .replace(text, @"<b>$text</b>"));

            Idle.add(() => {
                completion_list.insert(r, -1);
                return (false);
            });
        }
    }

    void on_activate()
    {
        var actives = completion_list.get_selected_rows();
        var _children = completion_list.get_children();

        if (actives.length() > 0 || _children.length() > 0)
        {
            // Do something
            var l = (actives.length() > 0) ?
                (CompletionListRow) actives.first().data :
                (CompletionListRow) _children.first().data;

            win.activate_action("open_file", l.text);
            palette.hide();
        }
    }

    void build_ui()
    {
        var b = new Gtk.Builder.from_resource(
            "/com/raggesilver/Proton/layouts/command_palette.ui");
        palette = (Gtk.Box) b.get_object("box");
        entry = (Gtk.Entry) b.get_object("entry");
        stack = (Gtk.Stack) b.get_object("stack");
        completion_list = (Gtk.ListBox) b.get_object("completion_list");
        var ev = (Gtk.EventBox) b.get_object("ev");

        entry.changed.connect(() => {
            do_completion();
        });

        entry.activate.connect(on_activate);

        completion_list.set_sort_func((r1, r2) => {
            var l1 = (Gtk.Label) r1.get_child();
            var l2 = (Gtk.Label) r2.get_child();

            var res = l1.label.length - l2.label.length;

            return ((res != 0) ? res : strcmp(l1.label, l2.label));
        });

        ev.button_press_event.connect((e) => {
            if (e.type == Gdk.EventType.BUTTON_PRESS)
            {
                message("Would hide");
                // palette.hide();
            }
            return (false);
        });

        ev.key_press_event.connect((e) => {
            if (e.keyval == Gdk.Key.Escape)
                palette.hide();
            if (e.keyval == Gdk.Key.Alt_L)
                palette.hide();
            if (e.keyval == Gdk.Key.Return)
                on_activate();
            return (false);
        });

        win.overlay.add_overlay(palette);
        win.overlay.set_overlay_pass_through(palette, true);
    }
}
