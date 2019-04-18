/* runner.vala
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

public class Runner.Tab : Proton.BottomPanelTab
{
    public Proton.IdleTerminal terminal = null;

    internal Tab(Proton.Window win)
    {
        terminal = new Proton.IdleTerminal(win);
        // terminal.input_enabled = false;

        content = terminal;
        aux_content = null;

        name = "runner-tab";
        title = "BUILD";
    }
}

private class Runner.Plugin : Object, Proton.PluginIface
{
    Gtk.Button btn;
    Gtk.Image play_image;
    Gtk.Image stop_image;
    Tab       tab;


    bool                     working = false;
    bool                     can_run = false;
    Proton.FlatpakSubprocess fsp;
    Proton.File              project_file;

    unowned Proton.Window window;

    construct
    {
        play_image = new Gtk.Image.from_icon_name(
            "media-playback-start-symbolic", Gtk.IconSize.MENU);
        stop_image = new Gtk.Image.from_icon_name(
            "media-playback-stop-symbolic", Gtk.IconSize.MENU);

        btn = new Gtk.Button();

        btn.get_style_context().add_class("wide-button");
        btn.set_image(play_image);
        btn.show();

        btn.clicked.connect(on_btn_click);
    }

    public void do_register(Proton.PluginLoader loader)
    {
        window = loader.window;
        project_file = new Proton.File(window.root.path +
                                       "/.proton/settings.json");
    }

    void on_start() {
        btn.set_image(stop_image);
        working = true;

        Proton.settings.bottom_panel_visible = true;

        tab.terminal.reset(true, true);
        tab.focus_tab();
    }

    void on_finish() {
        btn.set_image(play_image);
        working = false;
    }

    void do_start()
    {
        tab.terminal.pty = new Vte.Pty.sync(Vte.PtyFlags.DEFAULT);

        try
        {
            fsp = new Proton.FlatpakSubprocess(window.root.path,
                                        {"make"},
                                        {"PATH=" + Environ.get_variable(
                                            Environ.get(), "PATH")},
                                        SubprocessFlags.NONE,
                                        tab.terminal.pty.fd,
                                        tab.terminal.pty.fd,
                                        tab.terminal.pty.fd);

            fsp.finished.connect((res) => {
                // tab.terminal.feed_child((char[])
                //     (@"Build finished with code: $(res.to_string())\n"));
                on_finish();
            });
        }
        catch (Error e)
        {
            tab.terminal.feed_child((char[])(@"Error: $(e.message)\n"));
            on_finish();
        }
    }

    bool get_project_options()
    {
        return (false);
    }

    void ask_create_project()
    {
        var w = new Setup(window);
        w.show();
    }

    void on_btn_click()
    {
        if (!can_run)
        {
            ask_create_project();
            return ;
        }

        if (!working)
        {
            on_start();
            do_start();
        }
        else
            fsp.kill();
    }

    public void activate()
    {
        tab = new Tab(window);

        window.left_hb_box.pack_start(btn);
        window.left_hb_box.reorder_child(btn, 0);

        if (project_file.exists && get_project_options())
        {
            window.bottom_panel.add_tab(tab);
        }
        else
        {
            // ...
        }
    }

    public void deactivate()
    {
        // FIXME not yet implemented
        tab.content.get_parent().remove(tab.content);
        window.left_hb_box.remove(btn);
    }
}

public Type register_plugin(Module module)
{
    return (typeof(Runner.Plugin));
}

