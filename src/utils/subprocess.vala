/* subprocess.vala
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

public abstract class Proton.Subprocess : Object
{
    public signal void finished(int status);

    public abstract int? get_pid();
    public abstract bool  kill();

    // public abstract async bool wait();
}

public class Proton.SubprocessLauncher : Object
{
    public static Subprocess launch(bool on_host,
                                    string? cwd,
                                    string[] argv,
                                    string[] envv,
                                    SubprocessFlags flags,
                                    int? _stdin = -1,
                                    int? _stdout = -1,
                                    int? _stderr = -1)
    {
        // Then return Proton.FlatpakSubprocess
        if (is_flatpak() && on_host)
        {
            return ((Subprocess) new FlatpakSubprocess(
                cwd, argv, envv, flags, _stdin, _stdout, _stderr));
        }
        else
        {
            return ((Subprocess) new RegularSubprocess(
                cwd, argv, envv, flags, _stdin, _stdout, _stderr));
        }
    }
}
