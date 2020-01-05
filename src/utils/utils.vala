/* utils.vala
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
    public bool is_flatpak()
    {
        return (FileUtils.test("/.flatpak-info", FileTest.EXISTS));
    }

    public bool run_async(string? cwd,
                          string command,
                          out Pid _pid,
                          out int standard_input = null,
                          out int standard_output = null,
                          out int standard_error = null)
    {
        try
        {
            string[] argv = {};

            if (is_flatpak())
            {
                argv += "flatpak-spawn";
                argv += "--host";
            }

            argv += "/usr/bin/bash";

            var env = Environ.get();

            foreach (var s in command.split(" "))
                argv += s;

            return Process.spawn_async_with_pipes(
                cwd,
                argv,
                env,
                0,
                null,
                out _pid,
                out standard_input,
                out standard_output,
                out standard_error
            );
        }
        catch (SpawnError e)
        {
            warning(e.message);
            return (false);
        }
    }

    /**
     * Spawn a host command (both on flatpak and host) and get output. Your
     * command must be wrapped in single quotes and should be properly escaped.
     */
    public bool spawn(string command, out string? stdout, out string? stderr,
                      out int? status) throws SpawnError
    {
        string cmd = "";

        if (is_flatpak())
        {
            cmd += "flatpak-spawn  --host ";
        }

        cmd += "/usr/bin/bash -c ";
        cmd += command;

        return (Process.spawn_command_line_sync(cmd,
                                                out stdout,
                                                out stderr,
                                                out status));
    }
}
