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
    public FwupdManager fwupd { get; construct set; }
    public Fwupd.Device device { get; construct set; }

    public signal void update (Fwupd.Device device, Fwupd.Release release);

    public FirmwareUpdateRow (FwupdManager fwupd, Fwupd.Device device) {
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

        var version_label = new Gtk.Label (device.latest_release.version) {
            wrap = true,
            xalign = 0
        };

        var update_button = new Gtk.Button.with_label ("") {
            valign = Gtk.Align.CENTER,
            sensitive = false
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 6
        };
        grid.attach (icon, 0, 0, 1, 2);
        grid.attach (device_name_label, 1, 0);
        grid.attach (version_label, 1, 1);
        grid.attach (update_button, 2, 0, 1, 2);

        switch (device.latest_release.flag) {
            case Fwupd.ReleaseFlag.IS_UPGRADE:
                if (device.latest_release.version == device.version) {
                    update_button.label = _("Up to date");
                    update_button.sensitive = false;
                    break;
                }

                update_button.label = _("Update");
                update_button.sensitive = true;
                update_button.clicked.connect (() => {
                    update (device, device.latest_release);
                });
                break;
            default:
                update_button.label = _("Up to date");
                update_button.sensitive = false;
                break;
        }

        add (grid);
    }
}
