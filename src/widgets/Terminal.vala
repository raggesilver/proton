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
}
