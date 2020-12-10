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

    construct {
        try {
            interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.fwupd", "/");
            print ("HostProduct: %s\n", interface.host_product);
        } catch (Error e) {
            warning ("Could not connect to color interface: %s", e.message);
        }
    }
}
