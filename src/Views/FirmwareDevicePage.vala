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

public class About.FirmwareDevicePage : Granite.SimpleSettingsPage {
    private Gtk.Label version_value_label;
    private Gtk.Label vendor_value_label;
    private Gtk.Grid guids_grid;
    private Gtk.Grid flags_grid;
    private Gtk.Label update_error_value_label;
    private Gtk.Label install_duration_value_label;

    private Gtk.Button verify_button;
    private Gtk.Button show_releases_button;

    public signal void verify (string device_id);
    public signal void show_releases (Device device);

    public FirmwareDevicePage (Device device) {
        Object (
            icon_name: device.icon,
            status: device.summary,
            title: device.name
        );

        version_value_label.label = device.version;
        vendor_value_label.label = device.vendor;
        foreach (var guid in device.guids) {
            var label = new Gtk.Label (guid) {
                xalign = 0,
                hexpand = true
            };
            guids_grid.add (label);
        }

        foreach (var device_flag in DeviceFlag.get_list (device.flags)) {
            var name = device_flag.to_string ();

            if (name != null) {
                var icon = new Gtk.Image () {
                    gicon = new ThemedIcon (device_flag.to_icon ()),
                    pixel_size = 16
                };
                var label = new Gtk.Label (name) {
                    xalign = 0,
                    hexpand = true
                };
                var grid = new Gtk.Grid () {
                    orientation = Gtk.Orientation.HORIZONTAL,
                    column_spacing = 8
                };

                grid.add (icon);
                grid.add (label);

                flags_grid.add (grid);
            }
        }

        update_error_value_label.label = device.update_error;

        if (device.install_duration > 0) {
            install_duration_value_label.label = "%lu s".printf (device.install_duration);
        }

        verify_button.sensitive = device.releases.length() > 0;
        verify_button.clicked.connect (() => {
            verify (device.id);
        });

        show_releases_button.sensitive = device.releases.length() > 0;
        show_releases_button.clicked.connect (() => {
            show_releases (device);
        });
    }

    construct {
        var version_label = new Gtk.Label (_("Current Version:")) {
            xalign = 1
        };

        version_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var vendor_label = new Gtk.Label (_("Vendor:")) {
            xalign = 1
        };

        vendor_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var guids_label = new Gtk.Label (_("GUIDs:")) {
            xalign = 1,
            yalign = 0
        };

        guids_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        var flags_label = new Gtk.Label (_("Flags:")) {
            xalign = 1,
            yalign = 0
        };

        flags_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 4
        };

        var update_error_label = new Gtk.Label (_("Update Error:")) {
            xalign = 1
        };

        update_error_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var install_duration_label = new Gtk.Label (_("Install Duration:")) {
            xalign = 1
        };

        install_duration_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        content_area.attach (version_label, 0, 1, 1, 1);
        content_area.attach (version_value_label, 1, 1, 1, 1);
        content_area.attach (vendor_label, 0, 2, 1, 1);
        content_area.attach (vendor_value_label, 1, 2, 1, 1);
        content_area.attach (guids_label, 0, 3, 1, 1);
        content_area.attach (guids_grid, 1, 3, 1, 1);
        content_area.attach (flags_label, 0, 4, 1, 1);
        content_area.attach (flags_grid, 1, 4, 1, 1);
        content_area.attach (update_error_label, 0, 5, 1, 1);
        content_area.attach (update_error_value_label, 1, 5, 1, 1);
        content_area.attach (install_duration_label, 0, 6, 1, 1);
        content_area.attach (install_duration_value_label, 1, 6, 1, 1);

        verify_button = new Gtk.Button.with_label (_("Verify"));
        show_releases_button = new Gtk.Button.with_label (_("Show Releases"));

        action_area.add (verify_button);
        action_area.add (show_releases_button);
    }
}
