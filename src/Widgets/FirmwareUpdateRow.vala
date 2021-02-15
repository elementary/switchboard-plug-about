/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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

public class About.Widgets.FirmwareUpdateRow : Gtk.ListBoxRow {
    public FirmwareManager fwupd { get; construct set; }
    public Firmware.Device device { get; construct set; }

    public signal void update (Firmware.Device device, Firmware.Release release);

    public FirmwareUpdateRow (FirmwareManager fwupd, Firmware.Device device) {
        Object (
            fwupd: fwupd,
            device: device
        );
    }

    construct {
        var icon = new Gtk.Image.from_icon_name (device.icon, Gtk.IconSize.DND) {
            pixel_size = 32
        };

        var device_name_label = new Gtk.Label (device.name) {
            halign = Gtk.Align.START,
            hexpand = true
        };
        device_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var version_label = new Gtk.Label ("") {
            wrap = true,
            xalign = 0
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 6
        };
        grid.attach (icon, 0, 0, 1, 2);
        grid.attach (device_name_label, 1, 0);
        grid.attach (version_label, 1, 1);

        Firmware.Release? latest_release = device.latest_release;
        if (latest_release != null) {
            version_label.label = latest_release.version;
            switch (latest_release.flag) {
                case Firmware.ReleaseFlag.IS_UPGRADE:
                    if (device.latest_release.version == device.version) {
                        break;
                    }

                    var update_button = new Gtk.Button.with_label (_("Update")) {
                        valign = Gtk.Align.CENTER
                    };
                    update_button.clicked.connect (() => {
                        update (device, device.latest_release);
                    });
                    grid.attach (update_button, 2, 0, 1, 2);
                    break;
            }
        }

        add (grid);
    }
}
