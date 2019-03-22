/* Core.vala
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

public class Proton.Core : Object {

    private static Proton.Core? instance = null;
    // private File makefile;
    public bool can_play { get; private set; default = false; }

    public signal void play_changed(bool p);
    public signal void monitor_changed(GLib.File f,
                                       GLib.File? other,
                                       FileMonitorEvent e);

    private Core() {
        /*try {
            makefile = new File(@"$(root.path)/Makefile");
            check_can_play();
            monitor = root.file.monitor_directory(FileMonitorFlags.WATCH_MOVES);
            monitor.changed.connect((f, of, e) => {

                if (e == GLib.FileMonitorEvent.RENAMED) {
                    print("File moved (%s) -> (%s)\n", f.get_path(), of.get_path());
                }

                monitor_changed(f, of, e);
                check_can_play();
            });
        } catch(GLib.Error error) {
            warning(error.message);
        }*/
    }

    // private void check_can_play() {
    //     this.can_play = makefile.exists;
    //     this.play_changed(this.can_play);
    // }

    public static Proton.Core get_instance() {
        if (instance == null)
            instance = new Proton.Core ();
        return instance;
    }
}
