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

const Gdk.RGBA solarized_palette[] = {
  /*
   * Solarized palette (1.0.0beta2):
   * http://ethanschoonover.com/solarized
   */
  { 0.02745,  0.211764, 0.258823, 1 },
  { 0.862745, 0.196078, 0.184313, 1 },
  { 0.521568, 0.6,      0,        1 },
  { 0.709803, 0.537254, 0,        1 },
  { 0.149019, 0.545098, 0.823529, 1 },
  { 0.82745,  0.211764, 0.509803, 1 },
  { 0.164705, 0.631372, 0.596078, 1 },
  { 0.933333, 0.909803, 0.835294, 1 },
  { 0,        0.168627, 0.211764, 1 },
  { 0.796078, 0.294117, 0.086274, 1 },
  { 0.345098, 0.431372, 0.458823, 1 },
  { 0.396078, 0.482352, 0.513725, 1 },
  { 0.513725, 0.580392, 0.588235, 1 },
  { 0.423529, 0.443137, 0.768627, 1 },
  { 0.57647,  0.631372, 0.631372, 1 },
  { 0.992156, 0.964705, 0.890196, 1 },
};

public class Proton.Terminal : Vte.Terminal {

    public weak Proton.Window window { get; construct; }

    Gdk.RGBA bg;
    Gdk.RGBA fg;

    public Terminal(Proton.Window _window) {
        Object (window: _window,
                allow_bold: true,
                allow_hyperlink: true);

        try
        {
            spawn_sync(Vte.PtyFlags.DEFAULT,
                       window.root.path,
                       {Environ.get_variable(Environ.get(), "SHELL")},
                       {"TERM=xterm-256color"},
                       SpawnFlags.DO_NOT_REAP_CHILD,
                       null, null, null);


            if (is_flatpak())
            {
                feed_child((char[]) ("flatpak-spawn --env=\"TERM=xterm-256color"
                    + "\" --host bash\n$(getent passwd $LOGNAME | cut -d: -f7)"
                    + "\nreset\n"));
            }
        }
        catch (Error e) { warning(e.message); }

        window.style_updated.connect(update_ui);

        update_ui();

        show();
    }

    private void update_ui() {
        window.get_style_context().lookup_color("theme_base_color", out bg);
        window.get_style_context().lookup_color("theme_fg_color", out fg);

        set_colors(fg, bg, solarized_palette);
    }
}

