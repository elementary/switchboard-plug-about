/*
 * Copyright (c) 2022 elementary, Inc. (https://elementary.io)
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

public class About.SystemUpgrade : Object {
    public void restart () {
        try {
            system_instance.reboot (false);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }

    public bool system_upgrade_available {
        get {
            if (system_upgrade_instance == null) {
                return false;
            }

            return system_upgrade_instance.system_upgrade_available;
        }
    }

    public void start_upgrade () {
        if (system_upgrade_instance == null) {
            system_upgrade_instance.start_upgrade ();
        }
    }

    public signal void system_upgrade_progress (int percentage);

    public signal void system_upgrade_finished ();

    construct {
        get_system_instance ();
        get_system_upgrade_instance ();
    }

    [DBus (name = "org.freedesktop.login1.Manager")]
    interface SystemInterface : Object {
        public abstract void reboot (bool interactive) throws GLib.Error;
    }

    private SystemInterface? system_instance;
    private void get_system_instance () {
        if (system_instance == null) {
            try {
                system_instance = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "org.freedesktop.login1",
                    "/org/freedesktop/login1"
                );
            } catch (GLib.Error e) {
                warning ("%s", e.message);
            }
        }
    }

    [DBus (name = "io.elementary.SystemUpgrade")]
    interface SystemUpgradeInterface : Object {
        public abstract bool system_upgrade_available { get; }

        public abstract void start_upgrade ();

        public signal void system_upgrade_progress (int percentage);

        public signal void system_upgrade_finished ();
    }

    private SystemUpgradeInterface? system_upgrade_instance;
    private void get_system_upgrade_instance () {
        if (system_upgrade_instance == null) {
            try {
                system_upgrade_instance = Bus.get_proxy_sync (
                    BusType.SESSION,
                    "io.elementary.settings-daemon",
                    "/io/elementary/settings_daemon"
                );

                system_upgrade_instance.system_upgrade_progress.connect ((percentage) => { system_upgrade_progress (percentage); });

                system_upgrade_instance.system_upgrade_finished.connect (() => { system_upgrade_finished (); });
            } catch (GLib.Error e) {
                warning ("%s", e.message);
            }
        }
    }
}
