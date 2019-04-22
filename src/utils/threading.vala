/* threading.vala
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

[Compact]
static void
maybe_create_output_stream(UnixOutputStream **ret,
                           int *fdptr,
                           bool needed)
{
    assert(ret != null);
    assert(*ret == null);
    assert(fdptr != null);

    if (needed && *fdptr > 2)
    {
        *ret = new UnixOutputStream(*fdptr, true);
    }
    else if (*fdptr != -1)
    {
        Posix.close(*fdptr);
    }

    *fdptr = -1;
}

[Compact]
static void
maybe_create_input_stream(UnixInputStream **ret,
                          int *fdptr,
                          bool needed)
{
    assert(ret != null);
    assert(*ret == null);
    assert(fdptr != null);

    if (needed && *fdptr > 2)
    {
        *ret = new UnixInputStream(*fdptr, true);
    }
    else if (*fdptr != -1)
    {
        Posix.close(*fdptr);
    }

    *fdptr = -1;
}

public class Proton.FlatpakSubprocess : Object {

    public signal void finished(int _res);
    public signal void the_potato_master();

    DBusConnection connection;
    SubprocessFlags flags;
    int _stdin = -1;
    int _stdout = -1;
    int _stderr = -1;

    uint sigterm;
    uint sigint;
    uint exited_subscription;
    ulong closed_connection_handler;

    public Pid pid { get; protected set; }

    public uint32 client_pid = 0;

    public UnixOutputStream stdin_pipe;
    public UnixInputStream stdout_pipe;
    public UnixInputStream stderr_pipe;

    string[] _env;
    string[] _argv;
    string?  _cwd;

    public FlatpakSubprocess(string? cwd,
                             string[] argv,
                             string[] env,
                             SubprocessFlags _flags,
                             int sin,
                             int sout,
                             int serr)
    {
        flags |= _flags;

        _stdin = sin;
        _stdout = sout;
        _stderr = serr;
        _env = env;
        _argv = argv;
        _cwd = cwd;
    }

    public bool init() throws Error
    {
        return (_init(_env, _argv, _cwd));
    }

    private bool _init(string[] env, string[] argv, string? cwd) throws Error {
        var fd_builder = new VariantBuilder(new VariantType("a{uh}"));
        var env_builder = new VariantBuilder(new VariantType("a{ss}"));
        var fd_list = new UnixFDList();
        Variant reply = null;
        Variant _params = null;
        int[2] stdin_pair = { -1, -1 };
        int[2] stdout_pair = { -1, -1 };
        int[2] stderr_pair = { -1, -1 };
        int stdin_handle = -1;
        int stdout_handle = -1;
        int stderr_handle = -1;

        connection = new DBusConnection.for_address_sync(
            Environ.get_variable(Environ.get(), "DBUS_SESSION_BUS_ADDRESS"),
            DBusConnectionFlags.AUTHENTICATION_CLIENT |
                DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
            null,
            null
        );

        connection.set_exit_on_close(false);

        /*
         * STDIN
         */

        if (_stdin != -1)
        {
            flags &= ~SubprocessFlags.STDIN_PIPE;
            stdin_pair[0] = _stdin;
            warning("STDIN SET %d", _stdin);
            _stdin = -1;
        }
        else if ((flags & SubprocessFlags.STDIN_INHERIT) != 0)
        {
            flags &= ~SubprocessFlags.STDIN_PIPE;
            stdin_pair[0] = stdin.fileno();
        }
        else if ((flags & SubprocessFlags.STDIN_PIPE) != 0)
        {
            if (!Unix.open_pipe(stdin_pair, Posix.FD_CLOEXEC))
            {
                warning("Couldn't open pipe.\n");
                return false;
            }
        }
        else
        {
            flags &= ~SubprocessFlags.STDIN_PIPE;
            stdin_pair[0] = Posix.open("/dev/null",
                                       Posix.FD_CLOEXEC | Posix.O_RDWR,
                                       0);
            if (stdin_pair[0] == -1)
            {
                warning("Couldn't open /dev/null.");
                return false;
            }
        }

        assert(stdin_pair[0] != -1);

        stdin_handle = fd_list.append(stdin_pair[0]);
        assert(stdin_handle != -1);

        /*
         * STDOUT
         */

        if (_stdout != -1)
        {
            flags &= ~SubprocessFlags.STDOUT_PIPE;
            stdout_pair[1] = _stdout;
            warning("STDOUT SET %d", _stdout);
            _stdout = -1;
        }
        else if ((flags & SubprocessFlags.STDOUT_SILENCE) != 0)
        {
            flags &= ~SubprocessFlags.STDOUT_PIPE;
            stdout_pair[1] = Posix.open("/dev/null",
                                        Posix.FD_CLOEXEC | Posix.O_RDWR,
                                        0);
            if (stdin_pair[1] == -1)
            {
                warning("Couldn't open /dev/null.");
                return false;
            }
        }
        else if ((flags & SubprocessFlags.STDOUT_PIPE) != 0)
        {
            if (!Unix.open_pipe(stdout_pair, Posix.FD_CLOEXEC))
            {
                warning("Couldn't open pipe.\n");
                return false;
            }
        }
        else
        {
            flags &= ~SubprocessFlags.STDOUT_PIPE;
            stdout_pair[1] = stdout.fileno();
        }

        assert(stdout_pair[1] != -1);

        stdout_handle = fd_list.append(stdout_pair[1]);
        assert(stdout_handle != -1);

        /*
         * STDERR
         */

        if (_stderr != -1)
        {
            flags &= ~SubprocessFlags.STDERR_PIPE;
            stderr_pair[1] = _stderr;
            warning("STDERR SET %d", _stderr);
            _stderr = -1;
        }
        else if ((flags & SubprocessFlags.STDERR_SILENCE) != 0)
        {
            flags &= ~SubprocessFlags.STDERR_PIPE;
            stderr_pair[1] = Posix.open("/dev/null",
                                        Posix.FD_CLOEXEC | Posix.O_RDWR,
                                        0);
            if (stderr_pair[1] == -1)
            {
                warning("Couldn't open /dev/null.");
                return false;
            }
        }
        else if ((flags & SubprocessFlags.STDERR_PIPE) != 0)
        {
            if (!Unix.open_pipe(stderr_pair, Posix.FD_CLOEXEC))
            {
                warning("Couldn't open pipe.\n");
                return false;
            }
        }
        else
        {
            flags &= ~SubprocessFlags.STDERR_PIPE;
            stderr_pair[1] = stderr.fileno();
        }

        assert(stderr_pair[1] != -1);

        stderr_handle = fd_list.append(stderr_pair[1]);
        assert(stderr_handle != -1);

        /*
         * Build FDs for the message
         */
        fd_builder.add("{uh}", 0, stdin_handle);
        fd_builder.add("{uh}", 1, stdout_handle);
        fd_builder.add("{uh}", 2, stderr_handle);

        maybe_create_output_stream(&stdin_pipe,
                                   &stdin_pair[1],
                                   (flags & SubprocessFlags.STDIN_PIPE) != 0);
        maybe_create_input_stream(&stdout_pipe,
                                  &stdout_pair[0],
                                  (flags & SubprocessFlags.STDOUT_PIPE) != 0);
        maybe_create_input_stream(&stderr_pipe,
                                  &stderr_pair[0],
                                  (flags & SubprocessFlags.STDERR_PIPE) != 0);

        /*
         * Create env
         */
        foreach (var ev in env) {
            string[] e = ev.split("=");

            if (e.length > 0)
                env_builder.add("{ss}", e[0], (e.length > 1) ? e[1] : "");
        }

        sigterm = Unix.signal_add(Posix.Signal.TERM, sigterm_handler);
        sigint = Unix.signal_add(Posix.Signal.INT, sigint_handler);

        exited_subscription = connection.signal_subscribe(
            null,
            "org.freedesktop.Flatpak.Development",
            "HostCommandExited",
            "/org/freedesktop/Flatpak/Development",
            null,
            DBusSignalFlags.NONE,
            host_command_exited_cb
        );

        closed_connection_handler = connection.on_closed.connect((v, err) => {
            exited_subscription = 0;
            print("Remote peer closed? %s, error is set? %s\n",
                (v) ? "yes" : "no", (err != null) ? err.message :"no");
        });

        _params = new Variant(
            "(^ay^aay@a{uh}@a{ss}u)",
            cwd ?? Environment.get_current_dir(),
            argv,
            fd_builder.end(),
            env_builder.end(),
            1
        );

        print("Calling HostCommand with %s\n", _params.print(true));

        reply = connection.call_with_unix_fd_list_sync(
            "org.freedesktop.Flatpak",
            "/org/freedesktop/Flatpak/Development",
            "org.freedesktop.Flatpak.Development",
            "HostCommand",
            _params,
            new VariantType("(u)"),
            DBusCallFlags.NONE,
            -1,
            fd_list,
            null,
            null
        );

        pid = *((Pid *) reply.get_data());

        return true;
    }

    private void host_command_exited_cb(DBusConnection _connection,
                                        string sender_name,
                                        string object_path,
                                        string interface_name,
                                        string signal_name,
                                        Variant parameters)
    {
        uint32 _pid = 0;
        uint32 _res = 0;

        if (!parameters.is_of_type(new VariantType("(uu)")))
            error("Invalid variant type");

        parameters.get("(uu)", ref _pid, ref _res);
        print("Host process %" + uint32.FORMAT + " exited with %"
            + uint32.FORMAT + "\n", client_pid, _res);
        the_potato_master();

        Idle.add(() => {
            finished((int) _res);
            print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n");
            return (false);
        });

        if (exited_subscription != 0)
        {
            connection.signal_unsubscribe(exited_subscription);
            exited_subscription = 0;
        }
    }

    private bool sigterm_handler() {
        warning("Got here");
        try {
            connection.call_sync(
                "org.freedesktop.Flatpak",
                "/org/freedesktop/Flatpak/Development",
                "org.freedesktop.Flatpak.Development",
                "HostCommandSignal",
                new Variant("(uub)", client_pid, Posix.Signal.TERM, true),
                null,
                DBusCallFlags.NONE, -1,
                null
            );
        } catch (Error e) { warning(e.message); return true; }

        Posix.kill(Posix.getpid(), Posix.Signal.TERM);

        return false;
    }

    public bool kill()
    {
        try {
            connection.call_sync(
                "org.freedesktop.Flatpak",
                "/org/freedesktop/Flatpak/Development",
                "org.freedesktop.Flatpak.Development",
                "HostCommandSignal",
                new Variant("(uub)", pid, Posix.Signal.TERM, true),
                null,
                DBusCallFlags.NONE, -1,
                null);
            return (true);
        }
        catch (Error e)
        {
            warning(e.message);
            return (false);
        }
    }

    private bool sigint_handler() {

        try {
            connection.call_sync(
                "org.freedesktop.Flatpak",
                "/org/freedesktop/Flatpak/Development",
                "org.freedesktop.Flatpak.Development",
                "HostCommandSignal",
                new Variant("(uub)", client_pid, Posix.Signal.INT, true),
                null,
                DBusCallFlags.NONE, -1,
                null
            );
        } catch (Error e) { warning(e.message); return true; }

        Posix.kill(Posix.getpid(), Posix.Signal.INT);

        return false;
    }
}

public class Proton.RegularSubprocess : Proton.Subprocess
{
    public Pid pid { get; protected set; }

    private GLib.Subprocess? sub = null;

    public SubprocessFlags flags;
    public int             _stdin = 0;
    public int             _stdout = 1;
    public int             _stderr = 2;

    public string[]        argv;
    public string[]        envv;
    public string?         cwd;

    public RegularSubprocess(string? cwd,
                             string[] argv,
                             string[] envv,
                             SubprocessFlags flags,
                             int _stdin,
                             int _stdout,
                             int _stderr)
    {
        this._stdin = _stdin;
        this._stdout = _stdout;
        this._stderr = _stderr;
        this.argv = argv;
        this.envv = envv;
        this.cwd = cwd;
        this.flags = flags;
    }

    public void start() throws Error
    {
        var sp = new GLib.SubprocessLauncher(flags);

        // Validate and set env variables one by one
        foreach (var s in envv)
        {
            var ss = s.index_of("=");
            if (ss != -1)
                sp.setenv(s.substring(0, ss - 1), s.offset(ss), true);
        }

        if (cwd != null)
            sp.set_cwd(cwd);

        if (_stdin != -1)
            sp.take_stdin_fd(_stdin);

        if (_stderr != -1)
            sp.take_stderr_fd(_stderr);

        if (_stdout != -1)
            sp.take_stdout_fd(_stdout);

        sub = sp.spawnv(argv);
        sub.wait_async.begin(null, (_, res) => {
            sub.wait_async.end(res);
            finished(sub.get_exit_status());
        });
    }

    public override bool kill() {
        // sub.send_signal(Posix.Signal.KILL);
        sub.force_exit();

        return (true);
    }

    public override int? get_pid()
    {
        if (sub == null)
            return (null);
        return (int.parse(sub.get_identifier()));
    }
}
