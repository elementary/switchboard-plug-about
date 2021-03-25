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
    public signal void update (Fwupd.Device device, Fwupd.Release release);

    private Granite.Widgets.AlertView placeholder;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Stack content;
    private Gtk.Revealer update_button_revealer;
    private Gtk.Button update_button;
    private Gtk.Label title_label;
    private Gtk.Label summary_label;
    private Gtk.Label description_label;
    private Gtk.Label version_value_label;
    private Gtk.Label vendor_value_label;
    private Gtk.Label size_value_label;
    private Gtk.Label install_duration_value_label;
    private Hdy.Deck? deck;

    construct {
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

        update_button_revealer = new Gtk.Revealer ();
        update_button_revealer.add (update_button);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };
        header_box.pack_start (back_button);
        header_box.set_center_widget (title_label);
        header_box.pack_end (update_button_revealer);

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

        var key_val_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 6,
            halign = Gtk.Align.CENTER,
            margin_top = 12,
            row_spacing = 3
        };
        key_val_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        key_val_grid.attach (version_label, 0, 0);
        key_val_grid.attach (version_value_label, 1, 0);
        key_val_grid.attach (vendor_label, 0, 1);
        key_val_grid.attach (vendor_value_label, 1, 1);
        key_val_grid.attach (size_label, 0, 2);
        key_val_grid.attach (size_value_label, 1, 2);
        key_val_grid.attach (install_duration_label, 0, 3);
        key_val_grid.attach (install_duration_value_label, 1, 3);

        placeholder = new Granite.Widgets.AlertView (
            "",
            _("There are no releases available for this device."),
            ""
        );
        placeholder.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        var grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER,
            margin = 12,
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 12,
            vexpand = true
        };
        grid.add (summary_label);
        grid.add (description_label);
        grid.add (key_val_grid);

        scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true
        };
        scrolled_window.add (grid);

        content = new Gtk.Stack ();
        content.add (placeholder);
        content.add (scrolled_window);

        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        add (header_box);
        add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        add (content);
        show_all ();

        back_button.clicked.connect (() => {
            go_back ();
        });
    }

    public void update_view (Fwupd.Device device, Fwupd.Release? release) {
        title_label.label = "<b>%s</b>".printf (device.get_name ());
        update_button_revealer.reveal_child = release != null;

        if (release == null) {
            placeholder.title = device.get_name ();

            var icons = device.get_icons ();
            if (icons.data != null) {
                placeholder.icon_name = icons.data[0];
            } else {
                placeholder.icon_name = "application-x-firmware";
            }

            content.visible_child = placeholder;

            return;
        }

        content.visible_child = scrolled_window;

        switch (release.get_flags ()) {
            case Fwupd.RELEASE_FLAG_IS_UPGRADE:
                if (release.get_version () == device.get_version ()) {
                    update_button.label = _("Up to date");
                    update_button.sensitive = false;
                    break;
                }

                update_button.label = _("Update");
                update_button.sensitive = true;

                update_button.clicked.connect (() => {
                    go_back ();
                    update (device, release);
                });

                break;
            default:
                update_button.label = _("Up to date");
                update_button.sensitive = false;
                break;
        }

        summary_label.label = release.get_summary ();
        try {
            description_label.label = AppStream.markup_convert_simple (release.get_description ());
        } catch (Error e) {
            description_label.label = "";
            warning ("Could not convert markup of release: %s", e.message);
        }
        version_value_label.label = release.get_version ();
        vendor_value_label.label = release.get_vendor ();
        size_value_label.label = GLib.format_size (release.get_size ());

        uint32 duration_minutes = release.get_install_duration () / 60;
        if (duration_minutes < 1) {
            install_duration_value_label.label = _("less than a minute");
        } else {
            install_duration_value_label.label = GLib.ngettext ("%llu minute", "%llu minutes", duration_minutes).printf (duration_minutes);
        }

        show_all ();
    }

    private void go_back () {
        if (deck == null) {
            deck = (Hdy.Deck) get_ancestor (typeof (Hdy.Deck));
        }

        deck.navigate (Hdy.NavigationDirection.BACK);
    }
}
