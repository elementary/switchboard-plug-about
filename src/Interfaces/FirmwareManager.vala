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

public class About.FirmwareManager : Object {
    [DBus (name = "org.freedesktop.fwupd")]
    private interface FirmwareInterface : Object {
        public abstract signal void device_added (GLib.HashTable<string, Variant> device);
        public abstract signal void device_removed (GLib.HashTable<string, Variant> device);

        public abstract async GLib.HashTable<string, Variant>[] get_devices () throws GLib.Error;
        public abstract async GLib.HashTable<string, Variant>[] get_releases (string device_id) throws GLib.Error;
        public abstract async void install (string id, UnixInputStream handle, GLib.HashTable<string, Variant> options) throws GLib.Error;
        public abstract async GLib.HashTable<string, Variant>[] get_details (UnixInputStream handle) throws GLib.Error;
    }

    private Gee.Future<FirmwareInterface> fwupd_future;

    public signal void on_device_added (Firmware.Device device);
    public signal void on_device_error (Firmware.Device device, string error);
    public signal void on_device_removed (Firmware.Device device);

    private async FirmwareInterface? get_interface () {
        if (fwupd_future.ready) {
            return fwupd_future.value;
        }

        try {
            yield fwupd_future.wait_async ();
            return fwupd_future.value;
        } catch (Error e) {
            warning ("Unable to get fwupd interface: %s", e.message);
            return null;
        }
    }

    public async List<Firmware.Device> get_devices () {
        var devices_list = new List<Firmware.Device> ();

        var fwupd = yield get_interface ();
        if (fwupd == null) {
            return devices_list;
        }

        try {
            var result = yield fwupd.get_devices ();
            foreach (unowned GLib.HashTable<string, Variant> device in result) {
                devices_list.append (yield parse_device (device));
            }
        } catch (Error e) {
            warning ("Could not get devices: %s", e.message);
        }

        return devices_list;
    }

    private async List<Firmware.Release> get_releases (string id) {
        var releases_list = new List<Firmware.Release> ();

        var fwupd = yield get_interface ();
        if (fwupd == null) {
            return releases_list;
        }

        try {
            var result = yield fwupd.get_releases (id);
            foreach (unowned GLib.HashTable<string, Variant> release in result) {
                releases_list.append (parse_release (release));
            }
        } catch (Error e) {
            warning ("Could not get releases for “%s”: %s", id, e.message);
        }

        return releases_list;
    }

    private async Firmware.Device parse_device (GLib.HashTable<string, Variant> serialized_device) {
        var device = new Firmware.Device ();

        serialized_device.@foreach ((key, val) => {
            switch (key) {
                case "DeviceId":
                    device.id = val.get_string ();
                    break;
                case "Flags":
                    device.flags = (Firmware.DeviceFlag) val.get_uint64 ();
                    break;
                case "Name":
                    device.name = val.get_string ();
                    break;
                case "Summary":
                    device.summary = val.get_string ();
                    break;
                case "Vendor":
                    device.vendor = val.get_string ();
                    break;
                case "VendorId":
                    if (device.vendor == null) {
                        device.vendor = val.get_string ();
                    }
                    break;
                case "Version":
                    device.version = val.get_string ();
                    break;
                case "Icon":
                    var icons = val.get_strv ();
                    device.icon = icons.length > 0 ? icons[0] : "application-x-firmware";
                    break;
                case "Guid":
                    device.guids = val.get_strv ();
                    break;
                case "InstallDuration":
                    device.install_duration = val.get_uint32 ();
                    break;
                case "UpdateError":
                    device.update_error = val.get_string ();
                    break;
                default:
                    break;
            }
        });

        if (device.id.length > 0 && device.has_flag (Firmware.DeviceFlag.UPDATABLE)) {
            device.releases = yield get_releases (device.id);
        } else {
            device.releases = new List<Firmware.Release> ();
        }

        return device;
    }

    private Firmware.Release parse_release (GLib.HashTable<string, Variant> serialized_release) {
        var release = new Firmware.Release () {
            icon = "security-high"
        };

        serialized_release.@foreach ((key, val) => {
            switch (key) {
                case "Filename":
                    release.filename = val.get_string ();
                    break;
                case "Name":
                    release.name = val.get_string ();
                    break;
                case "Summary":
                    release.summary = val.get_string ();
                    break;
                case "Version":
                    release.version = val.get_string ();
                    break;
                case "Description":
                    release.description = val.get_string ()
                    .replace ("<p>", "")
                    .replace ("</p>", "\n\n")
                    .replace ("<li>", " • ")
                    .replace ("</li>", "\n")
                    .replace ("<ul>", "")
                    .replace ("</ul>", "\n")
                    .replace ("<ol>", "") // TODO: add support for ordered lists
                    .replace ("</ol>", "\n")
                    .strip ();
                    break;
                case "Protocol":
                    release.protocol = val.get_string ();
                    break;
                case "RemoteId":
                    release.remote_id = val.get_string ();
                    break;
                case "AppstreamId":
                    release.appstream_id = val.get_string ();
                    break;
                case "Checksum":
                    release.checksum = val.get_string ();
                    break;
                case "Vendor":
                    release.vendor = val.get_string ();
                    break;
                case "Size":
                    release.size = val.get_uint64 ();
                    break;
                case "License":
                    release.license = val.get_string ();
                    break;
                case "TrustFlags":
                    release.flag = (Firmware.ReleaseFlag) val.get_uint64 ();
                    break;
                case "InstallDuration":
                    release.install_duration = val.get_uint32 ();
                    break;
                case "Uri":
                    release.uri = val.get_string ();
                    break;
                default:
                    break;
            }
        });

        return release;
    }

    public async string? download_file (Firmware.Device device, string uri) {
        File server_file = File.new_for_uri (uri);
        var path = Path.build_filename (Environment.get_tmp_dir (), server_file.get_basename ());
        File local_file = File.new_for_path (path);

        bool result;
        try {
            result = yield server_file.copy_async (local_file, FileCopyFlags.OVERWRITE, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
                // TODO: provide useful information for user
            });
        } catch (Error e) {
            on_device_error (device, "Could not download file: %s".printf (e.message));
            return null;
        }

        if (!result) {
            on_device_error (device, "Download of %s was not succesfull".printf (uri));
            return null;
        }

        return path;
    }

    public async bool install (Firmware.Device device, string path) {
        var fwupd = yield get_interface ();
        if (fwupd == null) {
            // This should be unreachable since we wouldn't have a device to update
            // if we weren't able to get the fwupd interface
            return false;
        }

        int fd;

        try {
            // https://github.com/fwupd/fwupd/blob/c0d4c09a02a40167e9de57f82c0033bb92e24167/libfwupd/fwupd-client.c#L2045
            var options = new GLib.HashTable<string, Variant> (str_hash, str_equal);
            options.insert ("reason", new Variant.string ("user-action"));
            options.insert ("filename", new Variant.string (path));
            options.insert ("allow-older", new Variant.boolean (true));
            options.insert ("allow-reinstall", new Variant.boolean (true));
            options.insert ("no-history", new Variant.boolean (true));

            fd = Posix.open (path, Posix.O_RDONLY);
            var handle = new UnixInputStream (fd, true);

            yield fwupd.install (device.id, handle, options);
        } catch (Error e) {
            warning ("Could not install release for “%s”: %s", device.id, e.message);
            on_device_error (device, device.update_error != null ? device.update_error : e.message);
            return false;
        } finally {
            Posix.close (fd);
        }

        return true;
    }

    public async Firmware.Details get_release_details (Firmware.Device device, string path) {
        var details = new Firmware.Details ();

        var fwupd = yield get_interface ();
        if (fwupd == null) {
            // This should be unreachable since we wouldn't have a device to get details for
            // if we weren't able to get the fwupd interface
            return details;
        }

        int fd;
        try {
            fd = Posix.open (path, Posix.O_RDONLY);
            var handle = new UnixInputStream (fd, true);

            var result = yield fwupd.get_details (handle);
            foreach (unowned GLib.HashTable<string, Variant> serialized_details in result) {
                serialized_details.@foreach ((key, val) => {
                    if (key == "Release") {
                        var iter = val.iterator ().next_value ().iterator ();
                        string details_key;
                        Variant details_val;
                        while (iter.next ("{sv}", out details_key, out details_val)) {
                            if (details_key == "DetachCaption") {
                                details.caption = details_val.get_string ();
                            } else if (details_key == "DetachImage") {
                                details.image = details_val.get_string ();
                            }
                        }
                    }
                });
            }
        } catch (Error e) {
            warning ("Could not get details for “%s”: %s", device.id, e.message);
            on_device_error (device, device.update_error);
        } finally {
            Posix.close (fd);
        }

        if (details.image != null) {
            details.image = yield download_file (device, details.image);
        }

        return details;
    }

    construct {
        var promise = new Gee.Promise<FirmwareInterface> ();
        fwupd_future = promise.future;

        init_dbus.begin (promise);
    }

    private async void init_dbus (Gee.Promise<FirmwareInterface> promise) {
        try {
            FirmwareInterface bus_proxy = yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.fwupd", "/");

            bus_proxy.device_added.connect ((serialized_device) => {
                parse_device.begin (serialized_device, (obj, res) => {
                    var device = parse_device.end (res);
                    on_device_added (device);
                });
            });

            bus_proxy.device_removed.connect ((serialized_device) => {
                parse_device.begin (serialized_device, (obj, res) => {
                    var device = parse_device.end (res);
                    on_device_removed (device);
                });
            });

            promise.set_value (bus_proxy);
        } catch (Error e) {
            warning ("Could not connect to system bus: %s", e.message);
            promise.set_exception (e);
        }
    }
}
