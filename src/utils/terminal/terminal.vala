/* terminal.vala
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
    /* fp_guess_shell
     *
     * Copyright 2019 Christian Hergert <chergert@redhat.com>
     *
     * The following function is a derivative work of the code from
     * https://gitlab.gnome.org/chergert/flatterm which is licensed under the
     * Apache License, Version 2.0 <LICENSE-APACHE or
     * https://opensource.org/licenses/MIT>, at your option. This file may not
     * be copied, modified, or distributed except according to those terms.
     *
     * SPDX-License-Identifier: (MIT OR Apache-2.0)
     */
    public string? fp_guess_shell(Cancellable? cancellable = null) throws Error
    {
        if (!is_flatpak())
            return (Vte.get_user_shell());

        string[] argv = { "flatpak-spawn", "--host", "getent", "passwd",
            Environment.get_user_name() };

        var launcher = new GLib.SubprocessLauncher(
            SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
        );

        launcher.unsetenv("G_MESSAGES_DEBUG");
        var sp = launcher.spawnv(argv);

        if (sp == null)
            return (null);

        string? buf = null;
        if (!sp.communicate_utf8(null, cancellable, out buf, null))
            return (null);

        var parts = buf.split(":");

        if (parts.length < 7)
        {
            return (null);
        }

        return (parts[6].strip());
    }

    public string[]? fp_get_env(Cancellable? cancellable = null) throws Error
    {
        if (!is_flatpak())
            return (Environ.get());

        string[] argv = { "flatpak-spawn", "--host", "env" };

        var launcher = new GLib.SubprocessLauncher(
            SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
        );

        launcher.setenv("G_MESSAGES_DEBUG", "false", true);

        var sp = launcher.spawnv(argv);

        if (sp == null)
            return (null);

        string? buf = null;
        if (!sp.communicate_utf8(null, cancellable, out buf, null))
            return (null);

        string[] arr = buf.strip().split("\n");

        return (arr);
    }
}
