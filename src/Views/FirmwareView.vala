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

public class About.FirmwareView : Gtk.Stack {
    construct {
        var firmware_devices_view = new FirmwareDevicesView ();
        var firmware_releases_view = new FirmwareReleasesView ();

        firmware_devices_view.show_releases.connect ((device) => {
            firmware_releases_view.get_releases (device);
            set_visible_child_name ("releases");
        });

        add_named (firmware_devices_view, "devices");
        add_named (firmware_releases_view, "releases");
    }
}
