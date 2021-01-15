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

extern int ro_fd (string path);

public class About.FwupdManager : Object {
    private DBusConnection connection;

    public signal void changed ();

    public signal void on_error (string error);

    static FwupdManager? instance = null;
    public static FwupdManager get_instance () {
        if (instance == null) {
            instance = new FwupdManager ();
        }

        return instance;
    }

    private FwupdManager () {}

    public async List<Device> get_devices () {
        var devices_list = new List<Device> ();

        try {
            var result = yield connection.call (
                "org.freedesktop.fwupd",
                "/",
                "org.freedesktop.fwupd",
                "GetDevices",
                null,
                new VariantType ("(aa{sv})"),
                DBusCallFlags.NONE,
                -1
            );

            var array_iter = result.iterator ();
            GLib.Variant? element = array_iter.next_value ();
            array_iter = element.iterator ();

            while ((element = array_iter.next_value ()) != null) {
                GLib.Variant? val = null;
                string? key = null;

                var device_iter = element.iterator ();
                var device = new Device ();
                while (device_iter.next ("{sv}", out key, out val)) {
                    switch (key) {
                        case "DeviceId":
                            device.id = val.get_string ();
                            break;
                        case "Flags":
                            device.flags = val.get_uint64 ();
                            if (device.id.length > 0 && device.is (DeviceFlag.UPDATABLE)) {
                                device.releases = yield get_releases (device.id);
                            } else {
                                device.releases = new List<Release> ();
                            }
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
                }
                devices_list.append (device);
            }
        } catch (Error e) {
            warning ("Could not connect to fwupd interface: %s", e.message);
        }

        return devices_list;
    }

    private async List<Release> get_releases (string id) {
        var releases_list = new List<Release> ();

        try {
            var result = yield connection.call (
                "org.freedesktop.fwupd",
                "/",
                "org.freedesktop.fwupd",
                "GetReleases",
                new Variant (
                    "(s)",
                    id
                ),
                new VariantType ("(aa{sv})"),
                DBusCallFlags.NONE,
                -1
            );

            var array_iter = result.iterator ();
            GLib.Variant? element = array_iter.next_value ();
            array_iter = element.iterator ();

            while ((element = array_iter.next_value ()) != null) {
                GLib.Variant? val = null;
                string? key = null;

                var release_iter = element.iterator ();
                var release = new Release ();
                release.icon = "security-high";
                while (release_iter.next ("{sv}", out key, out val)) {
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
                            release.flag = ReleaseFlag.from_uint64 (val.get_uint64 ());
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
                }
                releases_list.append (release);
            }
        } catch (Error e) {
            warning ("Could not connect to fwupd interface: %s", e.message);
        }

        return releases_list;
    }

    private string get_path (string uri) {
        var parts = uri.split ("/");
        string file_path = parts[parts.length - 1];
        return Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), file_path);
    }

    public async string? download_file (string uri) {
        var path = get_path (uri);

        File server_file = File.new_for_uri (uri);
        File local_file = File.new_for_path (path);

        if (FileUtils.test (path, FileTest.IS_REGULAR)) {
            return path;
        }

        bool result;
        try {
            result = yield server_file.copy_async (local_file, FileCopyFlags.OVERWRITE, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {});
        } catch (Error e) {
            on_error ("Could not download file: %s".printf (e.message));
            return null;
        }

        if (!result) {
            on_error ("Download of %s was not succesfull".printf (uri));
            return null;
        }

        return path;
    }

    public async bool install (Device device, string path) {
        try {
            // https://github.com/fwupd/fwupd/blob/c0d4c09a02a40167e9de57f82c0033bb92e24167/libfwupd/fwupd-client.c#L2045
            var options = new VariantBuilder (new VariantType ("a{sv}"));
            options.add ("{sv}", "reason", new Variant.string ("user-action"));
            options.add ("{sv}", "filename", new Variant.string (path));
            options.add ("{sv}", "allow-older", new Variant.boolean (true));
            options.add ("{sv}", "allow-reinstall", new Variant.boolean (true));
            options.add ("{sv}", "no-history", new Variant.boolean (true));

            var fd = ro_fd (path);
            var stream = new UnixInputStream (fd, true);

            var fd_list = new UnixFDList ();
            fd_list.append (stream.fd);

            var parameters = new VariantBuilder (new VariantType ("(sha{sv})"));
            parameters.add_value (new Variant.string (device.id));
            parameters.add_value (new Variant.handle (0));
            parameters.add_value (options.end ());

            yield connection.call_with_unix_fd_list (
                "org.freedesktop.fwupd",
                "/",
                "org.freedesktop.fwupd",
                "Install",
                parameters.end (),
                null,
                DBusCallFlags.NONE,
                -1,
                fd_list
            );
        } catch (Error e) {
            warning ("Could not connect to fwupd interface: %s", e.message);
            on_error (device.update_error != null ? device.update_error : e.message);
            return false;
        }

        return true;
    }

    public async Details get_details (Device device, string path) {
        var details = new Details ();

        try {
            var fd = ro_fd (path);
            var stream = new UnixInputStream (fd, true);

            var fd_list = new UnixFDList ();
            fd_list.append (stream.fd);

            var parameters = new VariantBuilder (new VariantType ("(h)"));
            parameters.add_value (new Variant.handle (0));

            var r = yield connection.call_with_unix_fd_list (
                "org.freedesktop.fwupd",
                "/",
                "org.freedesktop.fwupd",
                "GetDetails",
                parameters.end (),
                new VariantType ("(aa{sv})"),
                DBusCallFlags.NONE,
                -1,
                fd_list
            );

            var array_iter = r.iterator ();
            GLib.Variant? element = array_iter.next_value ();
            array_iter = element.iterator ();

            while ((element = array_iter.next_value ()) != null) {
                GLib.Variant? val = null;
                string? key = null;

                var details_iter = element.iterator ();
                while (details_iter.next ("{sv}", out key, out val)) {
                    if (key == "Release") {
                        var release_iter = val.iterator ().next_value ().iterator ();
                        while (release_iter.next ("{sv}", out key, out val)) {
                            if (key == "DetachCaption") {
                                details.caption = val.get_string ();
                            } else if (key == "DetachImage") {
                                details.image = val.get_string ();
                            }
                        }
                    }
                }
            }
        } catch (Error e) {
            warning ("Could not connect to fwupd interface: %s", e.message);
            on_error (device.update_error);
        }

        if (details.image != null) {
            details.image = yield download_file (details.image);
        }

        return details;
    }

    construct {
        try {
            connection = Bus.get_sync (BusType.SYSTEM);
        } catch (Error e) {
            warning ("Could not connect to system bus: %s", e.message);
        }
    }
}
