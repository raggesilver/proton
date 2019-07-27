/* Terminal.vala
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

const Gdk.RGBA solarized_palette[] = {
  /*
   * Solarized palette (1.0.0beta2):
   * http://ethanschoonover.com/solarized
   */
  { 0.02745,  0.211764, 0.258823, 1 },
  { 0.862745, 0.196078, 0.184313, 1 },
  { 0.521568, 0.6,      0,        1 },
  { 0.709803, 0.537254, 0,        1 },
  { 0.149019, 0.545098, 0.823529, 1 },
  { 0.82745,  0.211764, 0.509803, 1 },
  { 0.164705, 0.631372, 0.596078, 1 },
  { 0.933333, 0.909803, 0.835294, 1 },
  { 0,        0.168627, 0.211764, 1 },
  { 0.796078, 0.294117, 0.086274, 1 },
  { 0.345098, 0.431372, 0.458823, 1 },
  { 0.396078, 0.482352, 0.513725, 1 },
  { 0.513725, 0.580392, 0.588235, 1 },
  { 0.423529, 0.443137, 0.768627, 1 },
  { 0.57647,  0.631372, 0.631372, 1 },
  { 0.992156, 0.964705, 0.890196, 1 },
};

public class Proton.Terminal : Vte.Terminal
{
    static uint sid;

    public unowned Proton.Window win { get; protected set; }
    public uint    id                { get; protected set; }
    public Pid     pid;

    private Gdk.RGBA bg;
    private Gdk.RGBA fg;

    public Terminal(Window _win,
                    string? command = null,
                    bool self_destroy = false)
    {
        Object(allow_bold: true,
               allow_hyperlink: true);

        this.win = _win;
        this.id = sid++;

        this.spawn(command, self_destroy);

        win.style_updated.connect(this.update_ui);
        this.update_ui();

        this.connect_accels();
        show();
    }

    public Terminal.no_spawn(Window win)
    {
        Object(allow_bold: true, allow_hyperlink: true);

        this.win = win;
        this.id = sid++;

        win.style_updated.connect(this.update_ui);
        this.update_ui();

        this.connect_accels();
        show();
    }

    private void connect_accels()
    {
        this.win.on_accel.connect((ac) => {
            if (!this.has_focus)
                return (false);

            switch(ac)
            {
                case "<ctrl><shift>C":
                    if (!this.get_has_selection())
                        return (false);
                    this.copy_clipboard();
                    return (true);
                case "<ctrl><shift>V":
                    this.paste_clipboard();
                    return (true);
                default:
                    return (false);
            }
        });
    }

    private void update_ui()
    {
        win.get_style_context().lookup_color("theme_base_color", out bg);
        win.get_style_context().lookup_color("theme_fg_color", out fg);

        set_colors(fg, bg, solarized_palette);
    }

    public void spawn(string? command = null,
                       bool self_destroy = false)
    {
        try
        {
            if (is_flatpak())
            {
                string shell = fp_guess_shell() ?? "/usr/bin/bash";

                string[] real_argv = {
                    "/usr/bin/flatpak-spawn",
                    "--host",
                    "--watch-bus"
                };

		        var env = fp_get_env() ?? Environ.get();

		        env += "G_MESSAGES_DEBUG=false";
		        env += "TERM=xterm-256color";

		        for (uint i = 0; i < env.length; i++)
                    real_argv += @"--env=$(env[i])";

                real_argv += shell;
                if (command != null)
                {
                    real_argv += "-c";
                    real_argv += command;
                }
                else
                    real_argv += "--login";

                spawn_sync(
                    Vte.PtyFlags.NO_CTTY,
                    win.root.path,
                    real_argv,
                    env,
                    SpawnFlags.DO_NOT_REAP_CHILD,
                    null, out pid, null);
            }
            else
            {
                var env = Environ.get();
		        env += "G_MESSAGES_DEBUG=false";
		        env += "TERM=xterm-256color";

		        string[] argv = {
		            Environ.get_variable(Environ.get(), "SHELL")
		        };

		        if (command != null)
		        {
		            argv += "-c";
		            argv += command;
		        }

                spawn_sync(Vte.PtyFlags.DEFAULT,
                       win.root.path,
                       argv,
                       env,
                       self_destroy ? 0 : SpawnFlags.DO_NOT_REAP_CHILD,
                       null, out pid, null);
            }
        }
        catch (Error e) { warning(e.message); }
    }
}

public class Proton.IdleTerminal : Vte.Terminal
{
    unowned Window win;

    Gdk.RGBA bg;
    Gdk.RGBA fg;

    public IdleTerminal(Window _win)
    {
        Object (allow_bold: true,
                allow_hyperlink: true);

        win = _win;

        win.style_updated.connect(update_ui);

        update_ui();

        show();
    }

    private void update_ui()
    {
        win.get_style_context().lookup_color("theme_base_color", out bg);
        win.get_style_context().lookup_color("theme_fg_color", out fg);

        set_colors(fg, bg, solarized_palette);
    }
}
