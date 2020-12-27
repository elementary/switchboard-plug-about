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

public class About.FirmwareView : Granite.SettingsPage {
    private Gtk.Button update_all_button;
    private Gtk.ListBox update_list;

    public FirmwareView () {
        Object (
            icon_name: "application-x-firmware",
            title: _("Firmware")
        );
    }

    construct {
        var header_icon = new Gtk.Image.from_icon_name ("application-x-firmware", Gtk.IconSize.DIALOG) {
            pixel_size = 48,
            valign = Gtk.Align.START
        };

        var title_label = new Gtk.Label (_("Firmware")) {
            ellipsize = Pango.EllipsizeMode.END,
            selectable = true,
            xalign = 0
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        update_all_button = new Gtk.Button.with_label (_("Update All")) {
            hexpand = true,
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            sensitive = false
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            margin = 12
        };

        update_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (update_list);

        var frame = new Gtk.Frame (null);
        frame.add (scrolled_window);

        grid.attach (header_icon, 0, 0);
        grid.attach (title_label, 1, 0);
        grid.attach (update_all_button, 2, 0);
        grid.attach (frame, 0, 1, 3, 1);

        add (grid);

        update_list_view ();
    }

    private void update_list_view () {
        foreach (Gtk.Widget element in update_list.get_children ()) {
            if (element is Gtk.ListBoxRow) {
                update_list.remove (element);
            }
        }

        foreach (var device in FwupdManager.get_instance ().get_devices ()) {
            if (device.is (DeviceFlag.UPDATABLE) && device.releases.length () > 0) {
                var widget = new Widgets.FirmwareUpdateWidget (device);
                update_list.add (widget);

                widget.on_updated.connect (update_list_view);
            }
        }

        update_list.show_all ();
    }
}
