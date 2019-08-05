# git.py
#
# Copyright 2019 Paulo Queiroz <pvaqueiroz@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later

import gi

gi.require_version('Proton', '1.0')
gi.require_version('Gtk', '3.0')
gi.require_version('Peas', '1.0')

from gi.repository import GObject, Gtk, Peas
from gi.repository import Proton

class GitPlugin(GObject.GObject, Peas.Activatable):

    __gtype_name__ = "GitPlugin"
    object = GObject.Property(type=GObject.Object)

    window = None
    status = None

    def do_activate(self):

        self.window = Proton.Window(self.object)
        #this.status = new Proton.Status(() => {
        #    return @"Running $(window.root.name)...";
        #}, Proton.StatusBox.Priority.MEDIUM);
        #this.window.status_box.add_status_show(this.status);

    def do_deactivate(self):
        print("YO DEACTIVATED")

    def do_update_state(self):
        print("YO UPDATED")
