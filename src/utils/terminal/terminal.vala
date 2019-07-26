/* terminal.vala
 *
 * Copyright 2019 Christian Hergert <chergert@redhat.com>
 *
 * The following code is a derivative work of the code from
 * https://gitlab.gnome.org/chergert/flatterm which is licensed under the Apache
 * License, Version 2.0 <LICENSE-APACHE or https://opensource.org/licenses/MIT>,
 * at your option. This file may not be copied, modified, or distributed except
 * according to those terms.
 *
 * SPDX-License-Identifier: (MIT OR Apache-2.0)
 */

namespace Proton
{
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
}
