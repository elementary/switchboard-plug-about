/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class About.DriverRow : Gtk.ListBoxRow {
    private static Gtk.SizeGroup button_size_group = new Gtk.SizeGroup (HORIZONTAL);

    public signal void install ();

    public string device { get; construct; }
    public string driver_name { get; construct; }
    public bool installed { get; construct; }

    public DriverRow (string device, string driver_name, bool installed) {
        Object (device: device, driver_name: driver_name, installed: installed);
    }

    construct {
        var icon = new Gtk.Image.from_icon_name ("application-x-firmware") {
            pixel_size = 32
        };

        var label = new Gtk.Label (driver_name) {
            hexpand = true,
            xalign = 0
        };

        var install_button = new Gtk.Button.with_label (installed ? _("Installed") : _("Install")) {
            sensitive = !installed,
            valign = CENTER
        };

        var box = new Gtk.Box (HORIZONTAL, 6);
        box.append (icon);
        box.append (label);
        box.append (install_button);

        child = box;

        install_button.clicked.connect (() => install ());

        button_size_group.add_widget (install_button);
    }
}
