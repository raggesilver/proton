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

    //  public delegate void HostCommandCb(int i);

    //  public Variant build_host_command_variant(string cwd, string[] args,
    //      string[] envv, uint[] handles)
    //  {
    //      if (cwd.length == 0) cwd = Environment.get_home_dir();

    //      var fd_builder = new VariantBuilder(new VariantType("a{uh}"));
    //      for (uint i = 0; i < handles.length; i++) {
    //          fd_builder.add_value(new Variant("uh", new Variant("u", i), new Variant("h", new Variant.handle((int32)handles[i]), true)));
    //      }

    //      var env_builder = new VariantBuilder(new VariantType("a{ss}"));
    //      foreach (var env in envv) {
    //          string[] env_pair = env.split("=");
    //          debug("Adding env var %s=%s", env_pair[0], env_pair[1]);
    //          if (env_pair.length == 2) {
    //              var pair = new Variant("ss", new Variant.string(env_pair[0]), new Variant.string(env_pair[1]));
    //              env_builder.add_value(pair);
    //          }
    //      }

    //      string[] argsv = {};
    //      string wd = cwd.dup();
    //      foreach (var arg in args) {
    //          argsv += arg;
    //      }
    //      argsv += null;

    //      var vs = new Variant("(^ay^aay@a{uh}@a{ss}u)",
    //          wd,
    //          argsv,
    //          fd_builder.end(),
    //          env_builder.end(),
    //          1);
    //      return new Variant.variant(vs);
    //  }

    //  public bool send_host_command(string cwd, string[] args, string[] envv,
    //      int[] stdio_fds, out int gpid, HostCommandCb cb) throws Error
    //  {
    //      uint[] handles = {};

    //      UnixFDList out_fd_list;
    //      UnixFDList in_fd_list = new UnixFDList();

    //      foreach (var fd in stdio_fds) {
    //          var i = in_fd_list.append(fd);
    //          handles += i;
    //          if (i == -1) {
    //              warning("Error creating fd list");
    //          }
    //      }

    //      DBusConnection connection = new DBusConnection.for_address_sync(
    //          Environ.get_variable(Environ.get(), "DBUS_SESSION_BUS_ADDRESS"),
    //          DBusConnectionFlags.AUTHENTICATION_CLIENT |
    //              DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
    //          null,
    //          null
    //      );

    //      connection.set_exit_on_close(false);

    //      uint sig_id = connection.signal_subscribe(
    //          "org.freedesktop.Flatpak",
    //          "org.freedesktop.Flatpak.Development",
    //          "HostCommandExited",
    //          "/org/freedesktop/Flatpak/Development",
    //          null,
    //          DBusSignalFlags.NONE,
    //          (DBusSignalCallback)cb
    //      );

    //      // https://github.com/gnunn1/tilix/blob/afdbcfe61991d1b40ae0d757b6f2c316bf712cc9/source/gx/tilix/terminal/terminal.d#L2798
    //      // search for hostcommand

    //      var reply = connection.call_with_unix_fd_list_sync(
    //          "org.freedesktop.Flatpak",
    //          "/org/freedesktop/Flatpak/Development",
    //          "org.freedesktop.Flatpak.Development",
    //          "HostCommand",
    //          build_host_command_variant(cwd, args, envv, handles),
    //          new VariantType("(u)"),
    //          DBusCallFlags.NONE,
    //          -1,
    //          in_fd_list,
    //          out out_fd_list,
    //          null
    //      );

    //      if (reply == null) {
    //          warning("No reply from flatpak dbus service");
    //          connection.signal_unsubscribe(sig_id);
    //          return false;
    //      } else {
    //          uint pid;
    //          reply.get("(u)", out pid);
    //          gpid = (int)pid;

    //          return true;
    //      }
    //  }
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
        // shell_arr += " --host /bin/bash".split(" ");

        try {
            var pty = new Vte.Pty.sync(Vte.PtyFlags.DEFAULT);
            var fd = pty.fd.to_string();

            print("Got fd %s\n", fd);

            set_pty(pty);

            string[] env = {};
            var envv = Environ.get();
            foreach (var k in envv) {
                string? s = Environ.get_variable(envv, k);
                if (s != null)
                    env += @"$k=$s";
            }

            env += "TERM=xterm-256color";

            spawn_sync(Vte.PtyFlags.DEFAULT,
                       root.path,
                       shell_arr,
                       env,
                       GLib.SpawnFlags.DO_NOT_REAP_CHILD,
                       null,
                       null);

            feed_child(@"flatpak-spawn --host /bin/bash\n".to_utf8());

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

        // Posix.system(@"get-passwd $suid");

        try {
            var kf = new KeyFile();
            kf.load_from_file("/.flatpak-info", KeyFileFlags.NONE);

            var host_root = kf.get_string("Instance", "app-path");
            string cmd = @"$host_root/bin/flatpak-toolbox get-passwd $suid";

            print(@"$cmd\n");

            string _stdout = null;
            string _stderr = null;

            int res = run(cmd, out _stdout, out _stderr);

            stdout.printf("Output: (%d) %s, %s\n", res, _stdout, _stderr);

            return "";
        } catch {
            return null;
        }
    }
}
