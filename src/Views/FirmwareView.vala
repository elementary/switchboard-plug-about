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

public class About.FirmwareView : Gtk.Stack {
    private Gtk.Grid grid;
    private Granite.Widgets.AlertView progress_alert_view;
    private Gtk.Grid progress_view;
    private Gtk.ListBox update_list;
    private Widgets.FirmwareHeaderRow updatable_header;
    private uint num_devices = 0;
    private uint num_updatable_devices = 0;
    private Widgets.FirmwareHeaderRow up_to_date_header;
    private FwupdManager fwupd;

    construct {
        fwupd = new FwupdManager ();

        transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        progress_alert_view = new Granite.Widgets.AlertView (
            "",
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

        add (grid);
        add (progress_view);

        fwupd.on_device_added.connect (on_device_added);
        fwupd.on_device_error.connect (on_device_error);
        fwupd.on_device_removed.connect (on_device_removed);

        update_list_view.begin ();
    }

    private async void update_list_view () {
        foreach (unowned Gtk.Widget widget in update_list.get_children ()) {
            if (widget is Widgets.FirmwareUpdateRow) {
                update_list.remove (widget);
            }

            num_updatable_devices = 0;
        }

        update_row_headers ();

        foreach (var device in yield fwupd.get_devices ()) {
            num_devices++;
            add_device (device);
        }

        visible_child = grid;
        update_list.show_all ();
    }

    private void add_device (Fwupd.Device device) {
        if (device.has_flag (Fwupd.DeviceFlag.UPDATABLE)) {
            var row = new Widgets.FirmwareUpdateRow (fwupd, device);

            int position = -1;
            if (device.releases.length () > 0 && device.latest_release.version != device.version) {
                num_updatable_devices++;
                position = 1;
            }
            update_row_headers ();

            update_list.insert (row, position);

            row.on_update_start.connect (() => {
                progress_alert_view.title = _("“%s” is being updated").printf (device.name);
                visible_child = progress_view;
            });
            row.on_update_end.connect (() => {
                visible_child = grid;
                update_list_view.begin ();
            });
        }
    }

    private void on_device_added (Fwupd.Device device) {
        debug ("Added device: %s", device.name);

        add_device (device);

        visible_child = grid;
        update_list.show_all ();
    }

    private void on_device_error (Fwupd.Device device, string error) {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Failed to install firmware release"),
            error,
            device.icon,
            Gtk.ButtonsType.CLOSE
        );
        message_dialog.transient_for = (Gtk.Window) get_toplevel ();
        message_dialog.badge_icon = new ThemedIcon ("dialog-error");
        message_dialog.show_all ();
        message_dialog.run ();
        message_dialog.destroy ();
    }

    private void on_device_removed (Fwupd.Device device) {
        debug ("Removed device: %s", device.name);

        foreach (unowned Gtk.Widget widget in update_list.get_children ()) {
            if (widget is Widgets.FirmwareUpdateRow) {
                var row = (Widgets.FirmwareUpdateRow) widget;
                if (row.device.id == device.id) {
                    update_list.remove (widget);
                }

                if (row.device.releases.length () > 0 && row.device.latest_release.version != row.device.version) {
                    num_updatable_devices--;
                }
            }
        }

        update_row_headers ();

        update_list.show_all ();
    }

    private void update_row_headers () {
        if (num_updatable_devices > 0 && updatable_header == null) {
            updatable_header = new Widgets.FirmwareHeaderRow.updatable (num_updatable_devices);
            updatable_header.show_all ();
            update_list.insert (updatable_header, 0);
        } else if (num_updatable_devices > 0) {
            updatable_header = new Widgets.FirmwareHeaderRow.updatable (num_updatable_devices);
            updatable_header.show_all ();
        } else if (num_updatable_devices == 0 && updatable_header != null) {
            updatable_header.destroy ();
            updatable_header = null;
        }

        if ((num_devices - num_updatable_devices) > 0 && up_to_date_header == null) {
            up_to_date_header = new Widgets.FirmwareHeaderRow.up_to_date ();
            up_to_date_header.show_all ();
            update_list.add (up_to_date_header);
        } else if (num_devices == 0 && up_to_date_header != null) {
            up_to_date_header.destroy ();
            up_to_date_header = null;
        }
    }
}
