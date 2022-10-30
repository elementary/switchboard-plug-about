/*
 * Copyright (c) 2021 elementary, Inc. (https://elementary.io)
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

[DBus (name = "org.freedesktop.login1.Manager")]
public interface About.LoginInterface : Object {
    public abstract void reboot (bool interactive) throws GLib.Error;
    public abstract void power_off (bool interactive) throws GLib.Error;
    public abstract void set_reboot_to_firmware_setup (bool interactive) throws GLib.Error;
    public abstract string can_reboot_to_firmware_setup () throws GLib.Error;
}

public class About.LoginManager : Object {
    private LoginInterface interface;

    static LoginManager? instance = null;
    public static LoginManager get_instance () {
        if (instance == null) {
            instance = new LoginManager ();
        }

        return instance;
    }

    private LoginManager () {}

    construct {
        try {
            interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (Error e) {
            warning ("Could not connect to login interface: %s", e.message);
        }
    }

    public bool shutdown () {
        try {
            interface.power_off (true);
        } catch (Error e) {
            warning ("Could not connect to login interface: %s", e.message);
            return false;
        }

        return true;
    }

    public bool reboot () {
        try {
            interface.reboot (true);
        } catch (Error e) {
            warning ("Could not connect to login interface: %s", e.message);
            return false;
        }

        return true;
    }

    public void set_reboot_to_firmware_setup () {
        try {
            interface.set_reboot_to_firmware_setup (true);
        } catch (Error e) {
            warning ("Could not connect to login interface: %s", e.message);
        }
    }

    public bool can_reboot_to_firmware_setup () {
        try {
            return interface.can_reboot_to_firmware_setup () == "yes";
        } catch (Error e) {
            warning ("Could not connect to login interface: %s", e.message);
        }

        return false;
    }
}
