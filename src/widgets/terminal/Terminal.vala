/* Terminal.vala
 *
 * Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * SPDX-License-Identifier: MIT
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
    unowned Proton.Window win;

    public uint id;
    static uint _id;

    Gdk.RGBA bg;
    Gdk.RGBA fg;

    public Terminal(Window _win,
                    string? command = null,
                    bool self_destroy = false)
    {
        Object (allow_bold: true,
                allow_hyperlink: true);

        win = _win;

        id = _id++;

        try
        {
            var shell = get_shell() ??
                        Environ.get_variable(Environ.get(), "SHELL");

            if (is_flatpak())
            {
                pty = new Vte.Pty.sync(Vte.PtyFlags.DEFAULT, null);
                fp_vte_pty_spawn_async.begin(
                    pty, _win.root.path, { shell }, {}, -1);
            }
            else
            {
                spawn_sync(Vte.PtyFlags.DEFAULT,
                           win.root.path,
                           { shell },
                           {"TERM=xterm-256color"},
                           self_destroy ? 0 : SpawnFlags.DO_NOT_REAP_CHILD,
                           null, null, null);
            }

            if (command != null)
                feed_child((char[]) command);
        }
        catch (Error e) { warning(e.message); }

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

    public static string? get_shell()
    {
        if (!is_flatpak())
            return (Environ.get_variable(Environ.get(), "SHELL"));

        string[] argv = { "flatpak-spawn", "--host", "getent", "passwd",
            Environment.get_user_name() };

        var launcher = new GLib.SubprocessLauncher(SubprocessFlags.STDOUT_PIPE |
                                              SubprocessFlags.STDERR_SILENCE);
        launcher.unsetenv("G_MESSAGES_DEBUG");

        try
        {
            var subprocess = launcher.spawnv(argv);
            string? sout = null;
            if (subprocess.communicate_utf8(null, null, out sout, null))
            {
                var arr = sout.split(":");
                if (arr.length < 7)
                    return (null);
                return (arr[6]);
            }
            return (null);
        }
        catch { return (null); }
    }

    public static int create_inferior_pty(int superior)
    {
        int fd = -1;

        if (superior == -1)
            return (-1);

        if (Posix.grantpt(superior) != 0)
            return (-1);

        if (Posix.unlockpt(superior) != 0)
            return (-1);

        char name[256];
        if (Linux.Termios.ptsname_r(superior, name) != 0)
            return (-1);

        fd = Posix.open((string) name, Posix.O_RDWR | Posix.FD_CLOEXEC);

        return (fd);
    }

    public static void fp_vte_pty_setup(Vte.Pty? pty)
    {
        if (pty != null && pty is Vte.Pty)
            pty.child_setup();
    }

    public static async void fp_vte_pty_spawn_async(
        Vte.Pty pty, string cwd, string[]? args, string[]? env, int timeout)
        throws Error
    {
        if (timeout < 0)
            timeout = -1;

        if (env == null)
        {
            string[] _env = {};
            foreach (string s in Environ.get())
                _env += s;
            env = _env;
        }

        int child_fd = -1;
        if ((child_fd = create_inferior_pty(pty.get_fd())) == -1)
            throw IOError.from_errno(Posix.errno);

        // var task = new Task(pty, null, fp_vte_pty_spawn_async.callback);
        // task.set_source_tag(fp_vte_pty_spawn_async);

        var launcher = new GLib.SubprocessLauncher(0);
        launcher.set_environ(env);
        launcher.set_cwd(cwd);
        launcher.take_stdout_fd(Posix.dup(child_fd));
        launcher.take_stderr_fd(Posix.dup(child_fd));
        launcher.take_stdin_fd(child_fd);
        launcher.set_child_setup(() => {
            fp_vte_pty_setup(is_flatpak() ? pty : null);
        });

        string[] argv = {};
        if (is_flatpak())
        {
            argv += "flatpak-spawn";
            argv += "--host";
            argv += "--watch-bus";
            for (int i = 0; i < env.length; i++)
                argv += "--env=%s".printf(env[i]);
        }

        for (int i = 0; i < args.length; i++)
            argv += args[i];

        launcher.spawnv(argv);
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
