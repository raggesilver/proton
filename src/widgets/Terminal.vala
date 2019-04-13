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

public class Proton.Terminal : Vte.Terminal
{
    unowned Proton.Window win;

    Gdk.RGBA bg;
    Gdk.RGBA fg;

    public Terminal(Window _win,
                    string? command = null,
                    bool self_destroy = false)
    {
        Object (allow_bold: true,
                allow_hyperlink: true);

        win = _win;

        try
        {
            spawn_sync(Vte.PtyFlags.DEFAULT,
                       win.root.path,
                       { Environ.get_variable(Environ.get(), "SHELL") },
                       {"TERM=xterm-256color"},
                       self_destroy ? 0 : SpawnFlags.DO_NOT_REAP_CHILD,
                       null, null, null);


            if (is_flatpak())
            {
                feed_child((char[]) ("flatpak-spawn --env=\"TERM=xterm-256color"
                    + "\" --host bash\n$(getent passwd $LOGNAME | cut -d: -f7)"
                    + "\nreset\n"));
            }

            if (command != null)
                feed_child((char[]) command);
        }
        catch (Error e) { warning(e.message); }

        win.style_updated.connect(update_ui);

        update_ui();

        show();
    }

    private void update_ui()
    {
        win.get_style_context().lookup_color("theme_base_color", out bg);
        win.get_style_context().lookup_color("theme_fg_color", out fg);

        set_colors(fg, bg, solarized_palette);
    }
}

public class Proton.IdleTerminal : Vte.Terminal
{
    unowned Window win;

    Gdk.RGBA bg;
    Gdk.RGBA fg;

    public IdleTerminal(Window _win)
    {
        Object (allow_bold: true,
                allow_hyperlink: true);

        win = _win;

        win.style_updated.connect(update_ui);

        update_ui();

        show();
    }

    private void update_ui()
    {
        win.get_style_context().lookup_color("theme_base_color", out bg);
        win.get_style_context().lookup_color("theme_fg_color", out fg);

        set_colors(fg, bg, solarized_palette);
    }
}

public class Proton.TerminalTab : Proton.BottomPanelTab
{
    unowned Window   win;

    Array<Terminal?> terminals;
    Gtk.ListStore    store;

    Gtk.Stack        stack;
    Gtk.ComboBox     combo;
    Gtk.Box          box;
    Gtk.Button       new_terminal_button;
    Gtk.Button       delete_terminal_button;

    public TerminalTab(Window _win)
    {
        name  = "terminal-tab";
        title = "TERMINAL";

        win = _win;
        terminals = new Array<Terminal?>();

        stack = new Gtk.Stack();
        store = new Gtk.ListStore(2, typeof(string), typeof(string));
        combo = new Gtk.ComboBox.with_model(store);

        combo.set_entry_text_column(1);
        combo.set_id_column(0);

        combo.changed.connect(on_changed);

        var renderer = new Gtk.CellRendererText();
        combo.pack_start(renderer, true);
        combo.add_attribute(renderer, "text", 1);

        box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        new_terminal_button = new Gtk.Button.from_icon_name("list-add-symbolic",
                                                            Gtk.IconSize.MENU);

        new_terminal_button.clicked.connect(() => { add_terminal(); });
        new_terminal_button.set_relief(Gtk.ReliefStyle.NONE);

        delete_terminal_button = new Gtk.Button.from_icon_name(
                                        "user-trash-symbolic",
                                        Gtk.IconSize.MENU);

        delete_terminal_button.clicked.connect(() => { delete_current_terminal(); });
        delete_terminal_button.set_relief(Gtk.ReliefStyle.NONE);

        box.pack_start(delete_terminal_button, false, true, 0);
        box.pack_start(new_terminal_button, false, true, 0);
        box.pack_end(combo, false, true, 0);

        stack.show();
        box.show_all();

        content = stack;
        aux_content = box;

        add_terminal();
    }

    public Terminal add_terminal(string? command = null,
                                 bool self_destroy = false)
    {
        var term = new Terminal(win, command, self_destroy);
        terminals.append_val(term);

        uint id = terminals.length;
        string sid = id.to_string();

        term.child_exited.connect(() => {
            delete_terminal(sid);
        });

        stack.add_named(terminals.index(id - 1), sid);

        Gtk.TreeIter it;
        store.append(out it);

        store.set(it,
                  0, sid,
                  1, @"$id: $(term.window_title)");

        term.window_title_changed.connect(() => {
            store.set(it, 1, @"$id: $(term.window_title)");
        });

        combo.set_active_id(sid);
        return (term);
    }

    void on_changed()
    {
        stack.set_visible_child_name(combo.active_id);
    }

    void delete_current_terminal()
    {
        var sid = combo.active_id;
        delete_terminal(sid);
    }

    public void delete_terminal(string sid)
    {
        var id = int.parse(sid) - 1;
        var term = terminals.index(id);

        if (term == null)
            return ;

        Gtk.TreeIter it;

        if (combo.get_active_iter(out it))
            store.remove(ref it);

        term.destroy();
        terminals.data[id] = null;

        if (stack.get_children().length() == 0)
            add_terminal();
        else
            combo.set_active_id(stack.get_visible_child_name());
    }
}
