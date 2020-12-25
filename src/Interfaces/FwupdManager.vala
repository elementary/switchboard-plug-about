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

[DBus (name="org.freedesktop.fwupd")]
public interface About.FwupdInterface : Object {
    [DBus (name = "HostProduct")]
    public abstract string host_product { owned get; }

    [DBus (name = "GetDevices")]
    public abstract HashTable<string, Variant>[] get_devices () throws Error;

    [DBus (name = "GetReleases")]
    public abstract HashTable<string, Variant>[] get_releases (string id) throws Error;

    [DBus (name = "Verify")]
    public abstract void verify (string id) throws Error;
}

public class About.FwupdManager : Object {
    private FwupdInterface interface;

    static FwupdManager? instance = null;
    public static FwupdManager get_instance () {
        if (instance == null) {
            instance = new FwupdManager ();
        }

        return instance;
    }

    private FwupdManager () {}

    public List<Device> get_devices () {
        var devices_list = new List<Device> ();

        try {
            foreach (var v in interface.get_devices ()) {
                var device = new Device ();
                foreach (var key in v.get_keys ()) {
                    switch (key) {
                        case "DeviceId":
                            device.id = v.lookup (key).get_string ();
                            device.releases = get_releases (device.id);
                            break;
                        case "Name":
                            device.name = v.lookup (key).get_string ();
                            break;
                        case "Summary":
                            device.summary = v.lookup (key).get_string ();
                            break;
                        case "Vendor":
                            device.vendor = v.lookup (key).get_string ();
                            break;
                        case "VendorId":
                            if (device.vendor == null) {
                                device.vendor = v.lookup (key).get_string ();
                            }
                            break;
                        case "Version":
                            device.version = v.lookup (key).get_string ();
                            break;
                        case "Icon":
                            var icons = v.lookup (key).get_strv ();
                            device.icon = icons.length > 0 ? icons[0] : "application-x-firmware";
                            break;
                        case "Guid":
                            device.guids = v.lookup (key).get_strv ();
                            break;
                        case "Flags":
                            device.flags = v.lookup (key).get_uint64 ();
                            break;
                        case "InstallDuration":
                            device.install_duration = v.lookup (key).get_uint32 ();
                            break;
                        case "UpdateError":
                            device.update_error = v.lookup (key).get_string ();
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

    private List<Release> get_releases (string id) {
        var releases_list = new List<Release> ();

        try {
            foreach (var v in interface.get_releases (id)) {
                var release = new Release ();
                release.icon = "security-high";
                foreach (var key in v.get_keys ()) {
                    switch (key) {
                        case "Filename":
                            release.filename = v.lookup (key).get_string ();
                            break;
                        case "Name":
                            release.name = v.lookup (key).get_string ();
                            break;
                        case "Summary":
                            release.summary = v.lookup (key).get_string ();
                            break;
                        case "Version":
                            release.version = v.lookup (key).get_string ();
                            break;
                        case "Description":
                            release.description = v.lookup (key).get_string ();
                            break;
                        case "Protocol":
                            release.protocol = v.lookup (key).get_string ();
                            break;
                        case "RemoteId":
                            release.remote_id = v.lookup (key).get_string ();
                            break;
                        case "AppstreamId":
                            release.appstream_id = v.lookup (key).get_string ();
                            break;
                        case "Checksum":
                            release.checksum = v.lookup (key).get_string ();
                            break;
                        case "Vendor":
                            release.vendor = v.lookup (key).get_string ();
                            break;
                        case "Size":
                            release.size = v.lookup (key).get_uint64 ();
                            break;
                        case "License":
                            release.license = v.lookup (key).get_string ();
                            break;
                        case "TrustFlags":
                            release.flag = ReleaseFlag.from_uint64 (v.lookup (key).get_uint64 ());
                            break;
                        case "InstallDuration":
                            release.install_duration = v.lookup (key).get_uint32 ();
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

    public void verify (string id) throws Error {
        interface.verify (id);
    }

    construct {
        try {
            interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.fwupd", "/");
        } catch (Error e) {
            warning ("Could not connect to fwupd interface: %s", e.message);
        }
    }
}
