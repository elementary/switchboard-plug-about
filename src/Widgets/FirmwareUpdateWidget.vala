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

public class About.Widgets.FirmwareUpdateWidget : Gtk.ListBoxRow {
    public Device device { get; construct set; }

    public signal void on_update_start ();
    public signal void on_update_end ();

    public FirmwareUpdateWidget (Device device) {
        Object (device: device);
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

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 6
        };
        grid.attach (icon, 0, 0, 1, 2);
        grid.attach (device_name_label, 1, 0);
        grid.attach (version_label, 1, 1);

        switch (device.latest_release.flag) {
            case ReleaseFlag.IS_UPGRADE:
                if (device.latest_release.version == device.version) {
                    add_up_to_date_label (grid);
                    break;
                }

                var update_button = new Gtk.Button.with_label (_("Update")) {
                    valign = Gtk.Align.CENTER
                };
                update_button.clicked.connect (() => {
                    on_update_start ();

                    FwupdManager.get_instance ().install.begin (device, device.latest_release, (obj, res) => {
                        FwupdManager.get_instance ().install.end (res);
                        on_update_end ();
                    });
                });
                grid.attach (update_button, 2, 0, 1, 2);
                break;
            default:
                add_up_to_date_label (grid);
                break;
        }

        add (grid);
    }

    private void add_up_to_date_label (Gtk.Grid grid) {
        var update_to_date_label = new Gtk.Label (_("Up to date")) {
            valign = Gtk.Align.CENTER
        };
        grid.attach (update_to_date_label, 2, 0, 1, 2);
    }
}
