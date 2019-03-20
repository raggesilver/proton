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

namespace Proton {
    public int run(string command, out string _stdout, out string _stderr) {
        int res = -1;
        try {
            stdout.printf("Running command: %s\n", command);
            Process.spawn_command_line_sync(
                command, out _stdout, out _stderr, out res);
        } catch(Error e) { warning(e.message); }
        return (res);
    }

    public delegate void HostCommandCb(int i);

    public bool send_host_command(string cwd, string[] args, string[] envv,
        int[] stdio_fds, out int gpid, HostCommandCb cb)
    {
        uint[] handles;

        UnixFDList out_fd_list;
        UnixFDList in_fd_list = new UnixFdList();

        foreach (var fd in stdio_fds) {
            var i = in_fd_list.append(fd);
            handles += i;
            if (i == -1) {
                warning("Error creating fd list");
            }
        }

        DBusConnection connection = new DBusConnection.for_address_sync(
            Environment.get("DBUS_SESSION_BUS_ADDRESS"),
            GDBusConnectionFlags.AUTHENTICATION_CLIENT |
                GDBusConnectionFlags.MESSAGE_BUS_CONNECTION,
            null,
            null
        );

        connection.set_exit_on_close(false);

        uint sig_id = connection.signal_subscribe(
            "org.freedesktop.Flatpak",
            "org.freedesktop.Flatpak.Development",
            "HostCommandExited",
            "org/freedesktop/Flatpak/Development",
            null,
            DBusSignalFlags.NONE,
            (DBusSignalCallback)cb
        );

        // https://github.com/gnunn1/tilix/blob/afdbcfe61991d1b40ae0d757b6f2c316bf712cc9/source/gx/tilix/terminal/terminal.d#L2798
        // search for hostcommand
        /*
        GVariant reply = connection.call_with_unix_fd_list_sync(
            "org.freedesktop.Flatpak",
            "/org/freedesktop/Flatpak/Development",
            "org.freedesktop.Flatpak.Development",
            "HostCommand",
        );
        */
       return false;
    }
}

public class Proton.Terminal : Vte.Terminal {
    private string shell;
    public weak Proton.Window window { get; construct; }

    public Terminal(Proton.Window _window) {
        Object (window: _window,
                allow_bold: true,
                allow_hyperlink: true);

        shell = GLib.Environ.get_variable(GLib.Environ.get(), "SHELL");
        string[] shell_arr = {shell};

        try {
            spawn_sync(Vte.PtyFlags.DEFAULT,
                       root.path,
                       shell_arr,
                       {},
                       GLib.SpawnFlags.DO_NOT_REAP_CHILD,
                       null,
                       null);
        } catch (GLib.Error error) {
            warning(error.message);
        }

        window.style_updated.connect(set_bg);
        set_bg();
        show();
    }

    private void set_bg() {
        Gdk.RGBA c;
        window.get_style_context().lookup_color("theme_base_color", out c);
        set_color_background(c);
    }

    private string? _get_shell() {
        var uid = Posix.getuid();
        var suid = ((uint)uid).to_string();

        Posix.system(@"get-passwd $suid");

        try {
            var kf = new KeyFile();
            kf.load_from_file("/.flatpak-info", KeyFileFlags.NONE);

            var host_root = kf.get_string("Instance", "app-path");
            string cmd = @"$host_root/bin/flatpak-toolbox get-passwd $suid";

            string _stdout = null;
            string _stderr = null;

            int res = run(cmd, out _stdout, out _stderr);

            stdout.printf("Output: (%d) %s, %s\n", res, _stdout, _stderr);

            return "";
        } catch(Error e) {
            (void)e;
            return null;
        }
    }
}
