/* Settings.vala
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

public class Proton.Settings : Granite.Services.Settings {

    private static Proton.Settings? instance = null;

    public bool dark_mode { get; set; }
    public int width { get; set; }
    public int height { get; set; }
    public int pos_x { get; set; }
    public int pos_y { get; set; }
    public string[] recent_projects { get; set; }
    public int bottom_panel_height { get; set; }
    public int left_panel_width { get; set; }
    public bool bottom_panel_visible { get; set; }
    public bool left_panel_visible { get; set; }

    private Settings() {
        base ("com.raggesilver.Proton");
    }

    public static Proton.Settings get_instance() {
        if (instance == null)
            instance = new Proton.Settings ();
        return instance;
    }

    public void add_recent(string s) {
        string[] _recent = {};
        _recent += s;
        foreach (var item in recent_projects) {
            if (!(item in _recent))
                _recent += item;
            if (_recent.length >= 5)
                break ;
        }
        recent_projects = _recent;
    }
}

