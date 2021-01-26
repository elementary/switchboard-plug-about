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
    public Fwupd.Device device { get; construct set; }
    public Fwupd.Release release { get; construct set; }

    public signal void back ();

    public FirmwareReleaseView (Fwupd.Device device, Fwupd.Release release) {
        Object (
            device: device,
            release: release
        );
    }

    construct {
        var back_button = new Gtk.Button.with_label (_("All Updates")) {
            halign = Gtk.Align.START,
            margin = 6
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label (device.name) {
            ellipsize = Pango.EllipsizeMode.END
        };

        var update_button = new Gtk.Button.with_label (_("Update")) {
            halign = Gtk.Align.END,
            margin = 6
        };
        update_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };
        header_box.pack_start (back_button);
        header_box.set_center_widget (title_label);
        header_box.pack_end (update_button);

        add (header_box);

        back_button.clicked.connect (() => {
            back ();
        });

        show_all ();
    }
}
