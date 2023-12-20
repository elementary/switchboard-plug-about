/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2023 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class About.FirmwareReleaseView : Gtk.Box {
    public signal void update (Fwupd.Device device, Fwupd.Release release);

    private Fwupd.Device device;
    private Fwupd.Release? release;
    private Granite.Widgets.AlertView placeholder;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Stack stack;
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
            halign = START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6,
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        title_label = new Gtk.Label ("") {
            ellipsize = END,
            use_markup = true
        };

        update_button = new Gtk.Button.with_label ("") {
            halign = END,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6,
            sensitive = false
        };
        update_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        update_button_revealer = new Gtk.Revealer () {
            child = update_button
        };

        var header_box = new Gtk.Box (HORIZONTAL, 6) {
            hexpand = true
        };
        header_box.pack_start (back_button);
        header_box.set_center_widget (title_label);
        header_box.pack_end (update_button_revealer);

        summary_label = new Gtk.Label ("") {
            halign = START,
            wrap = true
        };
        summary_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        description_label = new Gtk.Label ("") {
            halign = START,
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
            halign = CENTER,
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

        var box = new Gtk.Box (VERTICAL, 12) {
            halign = CENTER,
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12,
            vexpand = true
        };
        box.add (summary_label);
        box.add (description_label);
        box.add (key_val_grid);

        scrolled_window = new Gtk.ScrolledWindow (null, null) {
            child = box,
            hscrollbar_policy = NEVER,
            vexpand = true
        };

        stack = new Gtk.Stack ();
        stack.add (placeholder);
        stack.add (scrolled_window);

        orientation = VERTICAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        add (header_box);
        add (new Gtk.Separator (HORIZONTAL));
        add (stack);
        show_all ();

        back_button.clicked.connect (() => {
            go_back ();
        });

        update_button.clicked.connect (() => {
            go_back ();
            update (device, release);
        });
    }

    public void update_view (Fwupd.Device device, Fwupd.Release? release) {
        this.device = device;
        this.release = release;

        var device_name = device.get_name ();

        title_label.label = "<b>%s</b>".printf (device_name);
        update_button_revealer.reveal_child = release != null;

        if (release == null) {
            placeholder.title = device_name;

            var icons = device.get_icons ();
            if (icons.data != null) {
                placeholder.icon_name = icons.data[0];
            } else {
                placeholder.icon_name = "application-x-firmware";
            }

            stack.visible_child = placeholder;

            return;
        }

        stack.visible_child = scrolled_window;

        var release_version = release.get_version ();
        if (release.get_flags () == Fwupd.RELEASE_FLAG_IS_UPGRADE && release_version != device.get_version ()) {
            update_button.label = _("Update");
            update_button.sensitive = true;
        } else {
            update_button.label = _("Up to date");
            update_button.sensitive = false;
        }

        summary_label.label = release.get_summary ();
        try {
#if HAS_APPSTREAM_1_0
            description_label.label = AppStream.markup_convert (release.get_description (), AppStream.MarkupKind.XML);
#else
            description_label.label = AppStream.markup_convert_simple (release.get_description ());
#endif
        } catch (Error e) {
            description_label.label = "";
            warning ("Could not convert markup of release: %s", e.message);
        }
        version_value_label.label = release_version;
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

        deck.navigate (BACK);
    }
}
