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
    private Gtk.Stack stack;
    private Gtk.Frame frame;
    private Gtk.Grid progress_view;
    private Gtk.ListBox update_list;

    public FirmwareView () {
        Object (
            icon_name: "application-x-firmware",
            title: _("Firmware")
        );
    }

    construct {
        var progress_alert_view = new Granite.Widgets.AlertView (
            _("Device is being updated"),
            _("Do not unplug the device during the update."),
            "emblem-synchronized"
        );
        progress_alert_view.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        progress_view = new Gtk.Grid ();
        progress_view.margin = 24;
        progress_view.attach (progress_alert_view, 0, 0, 1, 1);

        var header_icon = new Gtk.Image.from_icon_name ("application-x-firmware", Gtk.IconSize.DIALOG) {
            pixel_size = 48,
            valign = Gtk.Align.START
        };

        var title_label = new Gtk.Label (_("Firmware")) {
            ellipsize = Pango.EllipsizeMode.END,
            hexpand = true,
            selectable = true,
            xalign = 0
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

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

        frame = new Gtk.Frame (null);
        frame.add (scrolled_window);

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add (frame);
        stack.add (progress_view);

        grid.attach (header_icon, 0, 0);
        grid.attach (title_label, 1, 0);
        grid.attach (stack, 0, 1, 3, 1);

        add (grid);

        update_list_view.begin ();
    }

    private async void update_list_view () {
        foreach (Gtk.Widget element in update_list.get_children ()) {
            if (element is Gtk.ListBoxRow) {
                update_list.remove (element);
            }
        }

        foreach (var device in yield FwupdManager.get_instance ().get_devices ()) {
            if (device.is (DeviceFlag.UPDATABLE) && device.releases.length () > 0) {
                var widget = new Widgets.FirmwareUpdateWidget (device);
                update_list.add (widget);

                widget.on_update_start.connect (() => {
                    stack.visible_child = progress_view;
                });
                widget.on_update_end.connect (() => {
                    stack.visible_child = frame;
                    update_list_view.begin ();
                });
            }
        }

        update_list.show_all ();
    }
}
