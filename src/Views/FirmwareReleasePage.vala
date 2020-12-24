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

public class About.FirmwareReleasePage : Granite.SimpleSettingsPage {
    private Gtk.Label version_value_label;
    private Gtk.Label summary_value_label;
    private Gtk.Label description_value_label;
    private Gtk.Label filename_value_label;
    private Gtk.Label protocol_value_label;
    private Gtk.Label remote_id_value_label;
    private Gtk.Label appstream_id_value_label;
    private Gtk.Label checksum_value_label;
    private Gtk.Label vendor_value_label;
    private Gtk.Label size_value_label;
    private Gtk.Label license_value_label;
    private Gtk.Label flags_value_label;
    private Gtk.Label install_duration_value_label;

    public FirmwareReleasePage (Release release) {
        Object (
            icon_name: release.icon,
            status: release.summary,
            title: release.name
        );

        version_value_label.label = release.version;

        summary_value_label.label = release.summary;

        description_value_label.label = release.description;

        filename_value_label.label = release.filename;

        protocol_value_label.label = release.protocol;

        remote_id_value_label.label = release.remote_id;

        appstream_id_value_label.label = release.appstream_id;

        checksum_value_label.label = release.checksum;

        vendor_value_label.label = release.vendor;

        size_value_label.label = "%.1f kB".printf ((release.size / 1000.0));

        license_value_label.label = release.license;

        flags_value_label.label = "%llu".printf (release.flags);

        if (release.install_duration > 0) {
            install_duration_value_label.label = "%lu s".printf (release.install_duration);
        }
    }

    construct {
        var version_label = new Gtk.Label (_("Version:")) {
            xalign = 1
        };

        version_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var summary_label = new Gtk.Label (_("Summary:")) {
            xalign = 1
        };

        summary_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var description_label = new Gtk.Label (_("Description:")) {
            xalign = 1,
            yalign = 0
        };

        description_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true,
            wrap = true
        };

        var filename_label = new Gtk.Label (_("Filename:")) {
            xalign = 1
        };

        filename_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var protocol_label = new Gtk.Label (_("Protocol:")) {
            xalign = 1
        };

        protocol_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var remote_id_label = new Gtk.Label (_("Remote ID:")) {
            xalign = 1
        };

        remote_id_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var appstream_id_label = new Gtk.Label (_("Appstream ID:")) {
            xalign = 1
        };

        appstream_id_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var checksum_label = new Gtk.Label (_("Checksum:")) {
            xalign = 1
        };

        checksum_value_label = new Gtk.Label ("") {
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

        var size_label = new Gtk.Label (_("Size:")) {
            xalign = 1
        };

        size_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var license_label = new Gtk.Label (_("License:")) {
            xalign = 1
        };

        license_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var flags_label = new Gtk.Label (_("Flags:")) {
            xalign = 1
        };

        flags_value_label = new Gtk.Label ("") {
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
        content_area.attach (summary_label, 0, 2, 1, 1);
        content_area.attach (summary_value_label, 1, 2, 1, 1);
        content_area.attach (description_label, 0, 3, 1, 1);
        content_area.attach (description_value_label, 1, 3, 1, 1);
        content_area.attach (filename_label, 0, 4, 1, 1);
        content_area.attach (filename_value_label, 1, 4, 1, 1);
        content_area.attach (protocol_label, 0, 5, 1, 1);
        content_area.attach (protocol_value_label, 1, 5, 1, 1);
        content_area.attach (remote_id_label, 0, 6, 1, 1);
        content_area.attach (remote_id_value_label, 1, 6, 1, 1);
        content_area.attach (appstream_id_label, 0, 7, 1, 1);
        content_area.attach (appstream_id_value_label, 1, 7, 1, 1);
        content_area.attach (checksum_label, 0, 8, 1, 1);
        content_area.attach (checksum_value_label, 1, 8, 1, 1);
        content_area.attach (vendor_label, 0, 9, 1, 1);
        content_area.attach (vendor_value_label, 1, 9, 1, 1);
        content_area.attach (size_label, 0, 10, 1, 1);
        content_area.attach (size_value_label, 1, 10, 1, 1);
        content_area.attach (license_label, 0, 11, 1, 1);
        content_area.attach (license_value_label, 1, 11, 1, 1);
        content_area.attach (flags_label, 0, 12, 1, 1);
        content_area.attach (flags_value_label, 1, 12, 1, 1);
        content_area.attach (install_duration_label, 0, 13, 1, 1);
        content_area.attach (install_duration_value_label, 1, 13, 1, 1);
    }
}
