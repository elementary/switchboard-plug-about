/*
* Copyright 2020-2021 elementary, Inc. (https://elementary.io)
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

public class About.FirmwareView : Granite.SimpleSettingsPage {
    private Gtk.Stack stack;
    private Hdy.Deck deck;
    private FirmwareReleaseView firmware_release_view;
    private Granite.Widgets.AlertView progress_alert_view;
    private Granite.Widgets.AlertView placeholder_alert_view;
    private Gtk.ListBox update_list;
    private uint num_updates = 0;
    private Fwupd.Client fwupd_client;

    public FirmwareView () {
        Object (
            icon_name: "application-x-firmware",
            title: _("Firmware"),
            description: _("New firmware is released by device manufacturers to improve performance, and fix security issues.")
        );
    }

    construct {
        progress_alert_view = new Granite.Widgets.AlertView (
            "",
            _("Do not unplug the device during the update."),
            "emblem-synchronized"
        );
        progress_alert_view.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        placeholder_alert_view = new Granite.Widgets.AlertView (
            _("Finding new firmware…"),
            _("Looking for software to be isntalled on actual hardware…"),
            "sync-synchronizing"
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

        var update_scrolled = new Gtk.ScrolledWindow (null, null);
        update_scrolled.add (update_list);

        firmware_release_view = new FirmwareReleaseView ();

        deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (update_scrolled);
        deck.add (firmware_release_view);
        deck.visible_child = update_scrolled;

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };
        stack.add (deck);
        stack.add (progress_alert_view);

        var frame = new Gtk.Frame (null);
        frame.add (stack);

        content_area.add (frame);

        fwupd_client = new Fwupd.Client ();
        FirmwareClient.connect.begin (fwupd_client, (obj, res) => {
            try {
                FirmwareClient.connect.end (res);

                fwupd_client.device_added.connect (on_device_added);
                fwupd_client.device_removed.connect (on_device_removed);

                update_list_view.begin ();
            } catch (Error e) {
                critical (e.message);
            }
        });

        update_list.row_activated.connect (show_release);

        firmware_release_view.update.connect ((device, release) => {
            update.begin (device, release);
        });
    }

    private async void update_list_view () {
        foreach (unowned Gtk.Widget widget in update_list.get_children ()) {
            if (widget is Widgets.FirmwareUpdateRow) {
                update_list.remove (widget);
            }
        }

        num_updates = 0;

        try {
            var devices = yield FirmwareClient.get_devices (fwupd_client);
            for (int i = 0; i < devices.length; i++) {
                add_device (devices[i]);
            }

            placeholder_alert_view.title = _("No new firmware found");
            placeholder_alert_view.description = _("Nothing on or connected to your system supports installing new firmware this way.");
            update_list.show_all ();
        } catch (Error e) {
            placeholder_alert_view.title = _("Firmware service unavailable");
            placeholder_alert_view.description = _("Ensure “fwupd” is installed and running.");
        }

        stack.visible_child = deck;
    }

    private void add_device (Fwupd.Device device) {
        if (device.has_flag (Fwupd.DEVICE_FLAG_UPDATABLE)) {
            FirmwareClient.get_upgrades.begin (fwupd_client, device.get_id (), (obj, res) => {
                Fwupd.Release? release = null;

                try {
                    var upgrades = FirmwareClient.get_upgrades.end (res);
                    if (upgrades != null) {
                        release = upgrades[0];
                    }
                } catch (Error e) {
                    debug (e.message);
                }

                var row = new Widgets.FirmwareUpdateRow (device, release);

                if (row.is_updatable) {
                    num_updates++;
                }

                update_list.add (row);
                update_list.invalidate_sort ();
                update_list.show_all ();

                row.update.connect ((device, release) => {
                    update.begin (device, release);
                });
            });
        }
    }

    private void show_release (Gtk.ListBoxRow widget) {
        if (widget is Widgets.FirmwareUpdateRow) {
            var row = (Widgets.FirmwareUpdateRow) widget;
            firmware_release_view.update_view (row.device, row.release);
            deck.visible_child = firmware_release_view;
        }
    }

    private void on_device_added (Fwupd.Client client, Fwupd.Device device) {
        debug ("Added device: %s", device.get_name ());

        add_device (device);

        stack.visible_child = deck;
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
                dngettext (GETTEXT_PACKAGE, "%u available firmware upgrade", "%u available firmware upgrades", num_updates).printf (num_updates)
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

    private async void update (Fwupd.Device device, Fwupd.Release release) {
        progress_alert_view.title = _("Installing new firmware on “%s”…").printf (device.get_name ());
        stack.visible_child = progress_alert_view;

        unowned var detach_caption = release.get_detach_caption ();
        if (detach_caption != null) {
            var detach_image = release.get_detach_image ();

            if (detach_image != null) {
                detach_image = yield download_file (device, detach_image);
            }

            if (show_details_dialog (device, detach_caption, detach_image) == false) {
                stack.visible_child = deck;
                return;
            }
        }

        var path = yield download_file (device, release.get_uri ());

        try {
            if (yield FirmwareClient.install (fwupd_client, device.get_id (), path)) {
                if (device.has_flag (Fwupd.DEVICE_FLAG_NEEDS_REBOOT)) {
                    show_reboot_dialog ();
                } else if (device.has_flag (Fwupd.DEVICE_FLAG_NEEDS_SHUTDOWN)) {
                    show_shutdown_dialog ();
                }
            }
        } catch (Error e) {
            show_error_dialog (device, e.message);
        }

        stack.visible_child = deck;
        update_list_view.begin ();
    }

    private async string? download_file (Fwupd.Device device, string uri) {
        var server_file = File.new_for_uri (uri);
        var path = Path.build_filename (Environment.get_tmp_dir (), server_file.get_basename ());
        var local_file = File.new_for_path (path);

        bool result;
        try {
            result = yield server_file.copy_async (local_file, FileCopyFlags.OVERWRITE, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
            // TODO: provide useful information for user
            });
        } catch (Error e) {
            show_error_dialog (device, "Could not download file: %s".printf (e.message));
            return null;
        }

        if (!result) {
            show_error_dialog (device, "Could not download %s".printf (uri));
            return null;
        }

        return path;
    }

    private void show_error_dialog (Fwupd.Device device, string secondary_text) {
        var gicon = new ThemedIcon ("application-x-firmware");
        var icons = device.get_icons ();
        if (icons.data != null) {
            gicon = new GLib.ThemedIcon.from_names (icons.data);
        }

        var message_dialog = new Granite.MessageDialog (
            _("Failed to install firmware release"),
            secondary_text,
            gicon,
            Gtk.ButtonsType.CLOSE
        ) {
            badge_icon = new ThemedIcon ("dialog-error"),
            transient_for = (Gtk.Window) get_toplevel ()
        };
        message_dialog.show_all ();
        message_dialog.run ();
        message_dialog.destroy ();
    }

    private bool show_details_dialog (Fwupd.Device device, string detach_caption, string? detach_image) {
        var gicon = new ThemedIcon ("application-x-firmware");
        var icons = device.get_icons ();
        if (icons.data != null) {
            gicon = new GLib.ThemedIcon.from_names (icons.data);
        }

        var message_dialog = new Granite.MessageDialog (
            _("Put “%s” in a firmware-upgradable mode manually").printf (device.get_name ()),
            detach_caption,
            gicon,
            Gtk.ButtonsType.CANCEL
        ) {
            badge_icon = new ThemedIcon ("dialog-information"),
            transient_for = (Gtk.Window) get_toplevel ()
        };

        var suggested_button = (Gtk.Button) message_dialog.add_button (_("Continue"), Gtk.ResponseType.ACCEPT);
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        if (detach_image != null) {
            var custom_widget = new Gtk.Image.from_file (detach_image);
            message_dialog.custom_bin.add (custom_widget);
        }

        message_dialog.show_all ();
        bool should_continue = message_dialog.run () == Gtk.ResponseType.ACCEPT;

        message_dialog.destroy ();

        return should_continue;
    }

    private void show_reboot_dialog () {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Restart the system to finish installing the new firmware"),
            _("This closes all open apps and restarts the device."),
            "application-x-firmware",
            Gtk.ButtonsType.CANCEL
        ) {
            badge_icon = new ThemedIcon ("system-reboot"),
            transient_for = (Gtk.Window) get_toplevel ()
        };

        var suggested_button = (Gtk.Button) message_dialog.add_button (_("Restart"), Gtk.ResponseType.ACCEPT);
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            LoginManager.get_instance ().reboot ();
        }

        message_dialog.destroy ();
    }

    private void show_shutdown_dialog () {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Shut down the system to finish installing the new firmware"),
            _("This closes all open apps and turns off this device."),
            "application-x-firmware",
            Gtk.ButtonsType.CANCEL
        ) {
            badge_icon = new ThemedIcon ("system-shutdown"),
            transient_for = (Gtk.Window) get_toplevel ()
        };

        var suggested_button = (Gtk.Button) message_dialog.add_button (_("Shut Down"), Gtk.ResponseType.ACCEPT);
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            LoginManager.get_instance ().shutdown ();
        }

        message_dialog.destroy ();
    }
}
