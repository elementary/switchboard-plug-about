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
    public abstract GLib.HashTable<string, Variant>[] get_devices () throws GLib.Error;
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
            foreach (var _device in interface.get_devices ()) {
                var device = new Device ();
                foreach (var key in _device.get_keys ()) {
                    switch (key) {
                        case "DeviceId":
                            device.id = _device.lookup (key).get_string ();
                            break;
                        case "Name":
                            device.name = _device.lookup (key).get_string ();
                            break;
                        case "Summary":
                            device.summary = _device.lookup (key).get_string ();
                            break;
                        case "Icon":
                            var icons = _device.lookup (key).get_strv ();
                            device.icon = icons.length > 0 ? icons[0] : "unknown";
                            break;
                        default:
                            break;
                    }
                }
                devices_list.append (device);
            }
        } catch (Error e) {
            warning ("Could not connect to color interface: %s", e.message);
        }

        return devices_list;
    }

    construct {
        try {
            interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.fwupd", "/");
        } catch (Error e) {
            warning ("Could not connect to color interface: %s", e.message);
        }
    }
}
