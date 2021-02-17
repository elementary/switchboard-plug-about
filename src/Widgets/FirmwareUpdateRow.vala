/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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

public class About.Widgets.FirmwareUpdateRow : Gtk.ListBoxRow {
    public Fwupd.Client client { get; construct set; }
    public Fwupd.Device device { get; construct set; }
    public bool is_updatable { get; private set; default = false; }

    public signal void on_update_start ();
    public signal void on_update_end ();

    private Gtk.Image image;

    public FirmwareUpdateRow (Fwupd.Client client, Fwupd.Device device) {
        Object (
            client: client,
            device: device
        );
    }

    construct {
        image = new Gtk.Image.from_icon_name ("application-x-firmware", Gtk.IconSize.DND) {
            pixel_size = 32
        };

        var device_name_label = new Gtk.Label (device.get_name ()) {
            halign = Gtk.Align.START,
            hexpand = true
        };
        device_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var version_label = new Gtk.Label (device.get_version ()) {
            wrap = true,
            xalign = 0
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin = 6
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (device_name_label, 1, 0);
        grid.attach (version_label, 1, 1);

        var icons = device.get_icons ();
        if (icons.data != null) {
            image.gicon = new GLib.ThemedIcon.from_names (icons.data);
        }

        FirmwareClient.get_upgrades.begin (client, device.get_id (), (obj, res) => {
            try {
                var upgrades = FirmwareClient.get_upgrades.end (res);
                if (upgrades != null) {
                    is_updatable = true;

                    var release = upgrades[0];
                    version_label.label = release.get_version ();

                    var update_button = new Gtk.Button.with_label (_("Update")) {
                        valign = Gtk.Align.CENTER
                    };
                    update_button.clicked.connect (() => {
                        on_update_start ();

                        update.begin (release, (obj, res) => {
                            update.end (res);
                            on_update_end ();
                        });
                    });
                    grid.attach (update_button, 2, 0, 1, 2);
                }
            } catch (Error e) {
                debug (e.message);
            }
        });


        add (grid);
    }

    private async void update (Fwupd.Release release) {
        unowned var detach_caption = release.get_detach_caption ();
        var detach_image = release.get_detach_image ();

        if (detach_image != null) {
            detach_image = yield download_file (detach_image);
        }

        if (detach_caption != null && show_details_dialog (detach_caption, detach_image) == false) {
            return;
        }

        var path = yield download_file (release.get_uri ());

        try {
            if (yield FirmwareClient.install (client, device.get_id (), path)) {
                if (device.has_flag (Fwupd.DEVICE_FLAG_NEEDS_REBOOT)) {
                    show_reboot_dialog ();
                } else if (device.has_flag (Fwupd.DEVICE_FLAG_NEEDS_SHUTDOWN)) {
                    show_shutdown_dialog ();
                }
            }
        } catch (Error e) {
            show_error_dialog (e.message);
        }
    }

    private async string? download_file (string uri) {
        var server_file = File.new_for_uri (uri);
        var path = Path.build_filename (Environment.get_tmp_dir (), server_file.get_basename ());
        var local_file = File.new_for_path (path);

        bool result;
        try {
            result = yield server_file.copy_async (local_file, FileCopyFlags.OVERWRITE, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
            // TODO: provide useful information for user
            });
        } catch (Error e) {
            show_error_dialog ("Could not download file: %s".printf (e.message));
            return null;
        }

        if (!result) {
            show_error_dialog ("Download of %s was not succesfull".printf (uri));
            return null;
        }

        return path;
    }

    private void show_error_dialog (string secondary_text) {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Failed to install firmware release"),
            secondary_text,
            image.icon_name,
            Gtk.ButtonsType.CLOSE
        ) {
            badge_icon = new ThemedIcon ("dialog-error"),
            transient_for = (Gtk.Window) get_toplevel ()
        };
        message_dialog.show_all ();
        message_dialog.run ();
        message_dialog.destroy ();
    }

    private bool show_details_dialog (string detach_caption, string detach_image) {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("“%s” needs to manually be put in update mode").printf (device.get_name ()),
            detach_caption,
            image.icon_name,
            Gtk.ButtonsType.CANCEL
        );
        message_dialog.transient_for = (Gtk.Window) get_toplevel ();

        var suggested_button = new Gtk.Button.with_label (_("Continue"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        if (detach_image != null) {
            var custom_widget = new Gtk.Image.from_file (detach_image);
            message_dialog.custom_bin.add (custom_widget);
        }

        message_dialog.badge_icon = new ThemedIcon ("dialog-information");
        message_dialog.show_all ();
        bool should_continue = message_dialog.run () == Gtk.ResponseType.ACCEPT;

        message_dialog.destroy ();

        return should_continue;
    }

    private void show_reboot_dialog () {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("An update requires the system to restart to complete"),
            _("This will close all open applications and restart this device."),
            "application-x-firmware",
            Gtk.ButtonsType.CANCEL
        );
        message_dialog.transient_for = (Gtk.Window) get_toplevel ();

        var suggested_button = new Gtk.Button.with_label (_("Restart"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        message_dialog.badge_icon = new ThemedIcon ("system-reboot");
        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            LoginManager.get_instance ().reboot ();
        }

        message_dialog.destroy ();
    }

    private void show_shutdown_dialog () {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("An update requires the system to shut down to complete"),
            _("This will close all open applications and turn off this device."),
            "application-x-firmware",
            Gtk.ButtonsType.CANCEL
        );
        message_dialog.transient_for = (Gtk.Window) get_toplevel ();

        var suggested_button = new Gtk.Button.with_label (_("Shut Down"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        message_dialog.badge_icon = new ThemedIcon ("system-shutdown");
        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            LoginManager.get_instance ().shutdown ();
        }

        message_dialog.destroy ();
    }
}
