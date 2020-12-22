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

public class About.FirmwareDevicesView : Gtk.Paned {
    public signal void verify (string device_id);
    public signal void show_releases (string device_id);

    construct {
        var stack = new Gtk.Stack ();

        var fwupd_manager = FwupdManager.get_instance ();
        foreach (var device in fwupd_manager.get_devices ()) {
            var page = new FirmwareDevicePage (device);
            page.verify.connect ((device_id) => {
                verify (device_id);
            });
            page.show_releases.connect ((device_id) => {
                show_releases (device_id);
            });

            stack.add_named (page, device.id);
        }

        var settings_sidebar = new Granite.SettingsSidebar (stack);

        add (settings_sidebar);
        add (stack);
    }
}
