/*
* Copyright (c) 2020 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
*/

public class About.FirmwareReleasesView : Gtk.Paned {
    private Gtk.Stack stack;

    construct {
        stack = new Gtk.Stack ();

        var settings_sidebar = new Granite.SettingsSidebar (stack);

        add (settings_sidebar);
        add (stack);
    }

    public void get_releases (string device_id) {
        foreach (Gtk.Widget element in stack.get_children ()) {
            stack.remove (element);
        }

        var fwupd_manager = FwupdManager.get_instance ();
        foreach (var release in fwupd_manager.get_releases (device_id)) {
            var page = new FirmwareReleasePage (release);

            stack.add_named (page, release.id);
        }
    }
}
