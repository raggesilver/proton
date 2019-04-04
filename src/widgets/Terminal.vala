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

using Posix;

[Compact]
static inline int pty_fd_steal(int *fd)
{
    int ret = *fd;
    *fd = -1;
    return ret;
}

[Compact]
int pty_intercept_create_slave(int master_fd, bool blocking)
{
    int ret = -1;
    int extra = (blocking) ? 0 : O_NONBLOCK;

    GLib.assert(master_fd != -1);

    if (grantpt(master_fd) != 0)
    {
        warning("grantpt");
        return -1;
    }

    if (unlockpt(master_fd) != 0)
    {
        warning("unlockpt");
        return -1;
    }

    var name = new char[4096];
    if (Linux.Termios.ptsname_r(master_fd, name) != 0)
    {
        warning("Linux thing failed: %s", (Posix.errno == EINVAL) ? "Buf null" : (Posix.errno == ERANGE) ? "buf too small" : "no tty");
        return -1;
    }

    ret = open((string)name, O_RDWR | FD_CLOEXEC | extra);
    if (ret == -1 && Posix.errno == EINVAL)
    {
        int flags;

        ret = open((string)name, O_RDWR | FD_CLOEXEC);
        if (ret == -1 && Posix.errno == EINVAL)
            ret = open((string)name, O_RDWR);

        if (ret == -1)
        {
            warning("Couldn't help it");
            return -1;
        }

        flags = fcntl(ret, F_GETFD, 0);
        if ((flags & FD_CLOEXEC) == 0)
        {
            if (fcntl(ret, F_SETFD, flags | FD_CLOEXEC) < 0)
            {
                warning("fcntl fail");
                return -1;
            }

            if (!blocking)
            {
                try {
                    if (!Unix.set_fd_nonblocking(ret, true))
                    {
                        warning("Blocking failed");
                        return -1;
                    }
                } catch {
                    warning("Explode");
                    return -1;
                }
            }
        }
    }

    return pty_fd_steal(&ret);
}

[Compact]
int pty_create_slave(Vte.Pty pty)
{
    int master_fd;

    master_fd = pty.get_fd();
    if (master_fd < 0)
    {
        warning("Invalid master_fd");
        return -1;
    }

    return pty_intercept_create_slave(master_fd, true);
}

public class Proton.Terminal : Vte.Terminal {

    public weak Proton.Window window { get; construct; }

    int tty_fd = -1;
    int out_fd = -1;
    int err_fd = -1;

    public Terminal(Proton.Window _window) {
        Object (window: _window,
                allow_bold: true,
                allow_hyperlink: true);

        if (is_flatpak())
        {
            if (!_init())
                warning("Couldn't initialize terminal");
        }
        else
        {
            try {
                spawn_sync(Vte.PtyFlags.DEFAULT,
                       window.root.path,
                       {Environ.get_variable(GLib.Environ.get(), "SHELL")},
                       {},
                       GLib.SpawnFlags.DO_NOT_REAP_CHILD,
                       null,
                       null);
            } catch {}
        }

        window.style_updated.connect(set_bg);
        set_bg();
        show();
    }

    private bool _init() {

        try {
            var pty = pty_new_sync(Vte.PtyFlags.DEFAULT |
                                   Vte.PtyFlags.NO_LASTLOG |
                                   Vte.PtyFlags.NO_UTMP |
                                   Vte.PtyFlags.NO_WTMP,
                                   null);
            set_pty(pty);

            if ((tty_fd = pty_create_slave(pty)) == -1)
            {
                warning("#1");
                return false;
            }

            if (tty_fd == GLib.stdin.fileno())
                warning("WHATTHEFUCK");

            if ((out_fd = dup(tty_fd)) == -1 || (err_fd = dup(tty_fd)) == -1)
            {
                warning("#2");
                return false;
            }

            var s = new FlatpakSubprocess(window.root.path,
                                          {"/bin/bash"},
                                          {"TERM=xterm-256color", "SHELL=/bin/bash"},
                                          SubprocessFlags.NONE,
                                          tty_fd,
                                          out_fd,
                                          err_fd);

            s.finished.connect(() => {
                // TODO connect this to a "destroy terminal tab" function
                print("terminal exited");
            });

            pty.child_setup();

        } catch (GLib.Error error) {
            warning(error.message);
            return false;
        }

        return true;
    }

    private void set_bg() {
        Gdk.RGBA c;
        window.get_style_context().lookup_color("theme_base_color", out c);
        set_color_background(c);
    }
}

