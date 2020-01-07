/* Cloner.vala
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

/*
** For whatever reason Ggit.RemoteCallbacks.new is protected, so a workarround
** is to create a derived class which has a public constructor
*/

public class Proton.RemoteCb : Ggit.RemoteCallbacks
{
    public signal void message(string text);
    public signal void percentage(double percentage);
    public signal void complete(bool res);
    public signal void error();

    construct
    {
        progress.connect((text) => { Idle.add(() => {
            debug("got text '%s'", text);
            message(text);
            return (false);
        }); });

        transfer_progress.connect((stats) => {

            uint rec, total, index;

            rec = stats.get_received_objects();
            total = stats.get_total_objects();
            index = stats.get_indexed_objects();

            var net_percent = (total > 0) ? rec * 100 / total / 2: 0;
            var ind_percent = (total > 0) ? index * 100 / total / 2 : 0;

            Idle.add(() => {
                percentage(net_percent + ind_percent);
                return (false);
            });
        });

        completion.connect((comp) => {
            debug("Hit complete");
            if (comp == Ggit.RemoteCompletionType.ERROR)
                Idle.add(() => {
                    error();
                    return (false);
                });
            else
                Idle.add(() => {
                    complete(true);
                    return (false);
                });
        });
    }
}

public class Proton.Cloner : Object
{
    public signal void complete(bool res);

    public RemoteCb          callbacks { get; protected set; }
    public Ggit.FetchOptions fetch_ops { get; protected set; }
    public Ggit.CloneOptions clone_ops { get; protected set; }
    public Ggit.Repository?  repo      { get; protected set; }

    string url;
    File   target;

    public Cloner(string url, File target) throws Error
    {
        assert_(Cloner.is_valid_target(target));
        assert_(Cloner.is_valid_url(url));

        Ggit.init();

        this.url = url;
        this.target = target;

        clone_ops = new Ggit.CloneOptions();
        fetch_ops = new Ggit.FetchOptions();
        callbacks = new RemoteCb();

        fetch_ops.set_remote_callbacks(callbacks);
        clone_ops.set_checkout_branch("master");
        clone_ops.set_fetch_options(fetch_ops);

        repo = null;
    }

    public static bool is_valid_target(File target)
    {
        return (!target.exists || target.is_empty);
    }

    public static bool is_valid_url(string url)
    {
        try
        {
            var r = new Regex(
                "((git|ssh|http(s)?)|(git@[\\w\\.]+))(:(//)?)([\\w\\."
                    + "@\\:/\\-~]+)(\\.git)(/)?",
                RegexCompileFlags.JAVASCRIPT_COMPAT
            );

            return (r.match(url));
        }
        catch(Error e)
        {
            warning(e.message);
            return (false);
        }
    }

    public void clone()
    {
        _do_clone.begin((obj, res) => {
            // Emit complete
            debug("Got to complete");
            complete(_do_clone.end(res));
        });
    }

    async bool _do_clone()
    {
        SourceFunc callback = _do_clone.callback;

        bool res = false;

        new Thread<bool>("git_clone", () => {
            try
            {
                repo = Ggit.Repository.clone(url, target.file, clone_ops);
                debug("Got to line after");
                assert_(repo != null);
                debug("Got after assert");

                Idle.add((owned)callback);

                res = true;
            }
            catch(Error e)
            {
                warning("Cloning %s failed.", url);
                warning(e.message);
                Idle.add((owned)callback);
            }
            return (true);
        });

        yield;

        return (res);
    }
}
