/*
 * Copyright (c) 2021 elementary, Inc. (https://elementary.io)
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

public class About.FirmwareReleaseView : Gtk.Grid {
    private Gtk.Button update_button;
    private Gtk.Label title_label;
    private Gtk.Label summary_label;
    private Gtk.Label description_label;
    private Gtk.Label version_value_label;
    private Gtk.Label vendor_value_label;
    private Gtk.Label size_value_label;
    private Gtk.Label install_duration_value_label;

    public signal void back ();
    public signal void update (Fwupd.Device device, Fwupd.Release release);

    public void update_view (Fwupd.Device device, Fwupd.Release release) {
        switch (release.flag) {
            case Fwupd.ReleaseFlag.IS_UPGRADE:
                if (release.version == device.version) {
                    update_button.label = _("Up to date");
                    update_button.sensitive = false;
                    break;
                }

                update_button.label = _("Update");
                update_button.sensitive = true;

                update_button.clicked.connect (() => {
                    update (device, release);
                });

                break;
            default:
                update_button.label = _("Up to date");
                update_button.sensitive = false;
                break;
        }

        title_label.label = "<b>%s</b>".printf (device.name);
        summary_label.label = release.summary;
        description_label.label = release.description;
        version_value_label.label = release.version;
        vendor_value_label.label = release.vendor;
        size_value_label.label = Formatter.bytes_to_string (release.size);
        install_duration_value_label.label = Formatter.seconds_to_string (release.install_duration);

        show_all ();
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        var back_button = new Gtk.Button.with_label (_("All Updates")) {
            halign = Gtk.Align.START,
            margin = 6
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        title_label = new Gtk.Label ("") {
            ellipsize = Pango.EllipsizeMode.END,
            use_markup = true
        };

        update_button = new Gtk.Button.with_label ("") {
            halign = Gtk.Align.END,
            margin = 6,
            sensitive = false
        };
        update_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };
        header_box.pack_start (back_button);
        header_box.set_center_widget (title_label);
        header_box.pack_end (update_button);

        summary_label = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            wrap = true
        };
        summary_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        description_label = new Gtk.Label ("") {
            halign = Gtk.Align.START,
            wrap = true
        };

        var version_label = new Gtk.Label (_("Version:")) {
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

        var size_label = new Gtk.Label (_("Size:")) {
            xalign = 1
        };

        size_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var install_duration_label = new Gtk.Label (_("Estimated time to install:")) {
            xalign = 1
        };

        install_duration_value_label = new Gtk.Label ("") {
            xalign = 0,
            hexpand = true
        };

        var content_area = new Gtk.Grid () {
            column_spacing = 12,
            halign = Gtk.Align.CENTER,
            margin = 12,
            row_spacing = 12,
            vexpand = true
        };

        content_area.attach (summary_label, 0, 0, 2);
        content_area.attach (description_label, 0, 1, 2);
        content_area.attach (version_label, 0, 2);
        content_area.attach (version_value_label, 1, 2);
        content_area.attach (vendor_label, 0, 3);
        content_area.attach (vendor_value_label, 1, 3);
        content_area.attach (size_label, 0, 4);
        content_area.attach (size_value_label, 1, 4);
        content_area.attach (install_duration_label, 0, 5);
        content_area.attach (install_duration_value_label, 1, 5);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true
        };
        scrolled_window.add (content_area);

        add (header_box);
        add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        add (scrolled_window);

        back_button.clicked.connect (() => {
            back ();
        });

        show_all ();
    }
}
