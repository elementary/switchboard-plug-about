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
    private Gtk.Grid grid;
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

        progress_view = new Gtk.Grid () {
            margin = 24
        };
        progress_view.attach (progress_alert_view, 0, 0);

        var no_devices_alert_view = new Granite.Widgets.AlertView (
            _("No Updatable Devices"),
            _("Firmware updates are not supported on this or any connected devices."),
            "application-x-firmware"
        );
        no_devices_alert_view.show_all ();
        no_devices_alert_view.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        update_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        update_list.set_placeholder (no_devices_alert_view);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (update_list);

        var frame = new Gtk.Frame (null);
        frame.add (scrolled_window);

        grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            margin = 12
        };
        grid.add (frame);

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add (grid);
        stack.add (progress_view);

        add (stack);

        FwupdManager.get_instance ().on_error.connect (on_error);

        update_list_view.begin ();
    }

    private async void update_list_view () {
        foreach (unowned Gtk.Widget widget in update_list.get_children ()) {
            if (widget is Gtk.ListBoxRow) {
                update_list.remove (widget);
            }
        }

        List<Device> devices = new List<Device> ();
        foreach (var device in yield FwupdManager.get_instance ().get_devices ()) {
            if (device.is (DeviceFlag.UPDATABLE) && device.releases.length () > 0) {
                devices.append (device);
            }
        }

        stack.visible_child = grid;

        foreach (var device in devices) {
            var widget = new Widgets.FirmwareUpdateWidget (device);
            update_list.add (widget);

            widget.on_update_start.connect (() => {
                stack.visible_child = progress_view;
            });
            widget.on_update_end.connect (() => {
                stack.visible_child = grid;
                update_list_view.begin ();
            });
        }

        update_list.show_all ();
    }

    private void on_error (string error) {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Failed to install firmware release"),
            error,
            "application-x-firmware",
            Gtk.ButtonsType.CLOSE
        );
        message_dialog.transient_for = (Gtk.Window) get_toplevel ();
        message_dialog.badge_icon = new ThemedIcon ("dialog-error");
        message_dialog.show_all ();
        message_dialog.run ();
        message_dialog.destroy ();
    }
}
