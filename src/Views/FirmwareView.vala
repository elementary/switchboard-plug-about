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
    private Granite.Widgets.AlertView placeholder_alert_view;
    private Gtk.Grid progress_view;
    private Gtk.ListBox update_list;
    private uint num_updates = 0;

    construct {
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

        placeholder_alert_view = new Granite.Widgets.AlertView (
            _("Checking for Updates"),
            _("Connecting to the firmware service and searching for updates."),
            "application-x-firmware"
        );
        placeholder_alert_view.show_all ();
        placeholder_alert_view.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        update_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        update_list.set_sort_func ((Gtk.ListBoxSortFunc) compare_rows);
        update_list.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) header_rows);
        update_list.set_placeholder (placeholder_alert_view);

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

        var fwupd_client = new Fwupd.Client ();
        FirmwareClient.connect.begin (fwupd_client, (obj, res) => {
            try {
                FirmwareClient.connect.end (res);

                fwupd_client.device_added.connect (on_device_added);
                fwupd_client.device_removed.connect (on_device_removed);

                update_list_view.begin (fwupd_client);
            } catch (Error e) {
                critical (e.message);
            }
        });
    }

    private async void update_list_view (Fwupd.Client client) {
        foreach (unowned Gtk.Widget widget in update_list.get_children ()) {
            if (widget is Widgets.FirmwareUpdateRow) {
                update_list.remove (widget);
            }
        }

        num_updates = 0;

        try {
            var devices = yield FirmwareClient.get_devices (client);
            for (int i = 0; i < devices.length; i++) {
                add_device (client, devices[i]);
            }

            placeholder_alert_view.title = _("Firmware Updates Are Not Available");
            placeholder_alert_view.description = _("Firmware updates are not supported on this or any connected devices.");
            update_list.show_all ();
        } catch (Error e) {
            placeholder_alert_view.title = _("The Firmware Service Is Not Available");
            placeholder_alert_view.description = _("Please make sure “fwupd” is installed and enabled.");
        }

        visible_child = grid;
    }

    private void add_device (Fwupd.Client client, Fwupd.Device device) {
        if (device.has_flag (Fwupd.DEVICE_FLAG_UPDATABLE)) {
            var row = new Widgets.FirmwareUpdateRow (client, device);

            if (row.is_updatable) {
                num_updates++;
            }

            update_list.add (row);
            update_list.invalidate_sort ();

            row.on_update_start.connect (() => {
                progress_alert_view.title = _("“%s” is being updated").printf (device.get_name ());
                visible_child = progress_view;
            });
            row.on_update_end.connect (() => {
                visible_child = grid;
                update_list_view.begin (client);
            });
        }
    }

    private void on_device_added (Fwupd.Client client, Fwupd.Device device) {
        debug ("Added device: %s", device.get_name ());

        add_device (client, device);

        visible_child = grid;
        update_list.show_all ();
    }

    private void on_device_removed (Fwupd.Client client, Fwupd.Device device) {
        debug ("Removed device: %s", device.get_name ());

        foreach (unowned Gtk.Widget widget in update_list.get_children ()) {
            if (widget is Widgets.FirmwareUpdateRow) {
                var row = (Widgets.FirmwareUpdateRow) widget;
                if (row.device.get_id () == device.get_id ()) {
                    if (row.is_updatable) {
                        num_updates--;
                    }

                    update_list.remove (widget);
                    update_list.invalidate_sort ();
                }
            }
        }

        update_list.show_all ();
    }

    [CCode (instance_pos = -1)]
    private int compare_rows (Widgets.FirmwareUpdateRow row1, Widgets.FirmwareUpdateRow row2) {
        if (row1.is_updatable && !row2.is_updatable) {
            return -1;
        }

        if (!row1.is_updatable && row2.is_updatable) {
            return 1;
        }

        return row1.device.get_name ().collate (row2.device.get_name ());
    }

    [CCode (instance_pos = -1)]
    private void header_rows (Widgets.FirmwareUpdateRow row1, Widgets.FirmwareUpdateRow? row2) {
        if (row2 == null && row1.is_updatable) {
            var header = new FirmwareHeaderRow (
                ngettext ("%u Update Available", "%u Updates Available", num_updates).printf (num_updates)
            );
            row1.set_header (header);
        } else if (row2 == null || row1.is_updatable != row2.is_updatable) {
            var header = new FirmwareHeaderRow (_("Up to Date"));
            row1.set_header (header);
        } else {
            row1.set_header (null);
        }
    }

    private class FirmwareHeaderRow : Gtk.Label {
        public FirmwareHeaderRow (string label) {
            Object (label: label);
        }

        construct {
            xalign = 0;
            margin = 3;
            get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        }
    }
}
