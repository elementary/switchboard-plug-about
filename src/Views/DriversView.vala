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

public class About.DriversView : Switchboard.SettingsPage {
    private Gtk.Stack stack;
    private Gtk.ListBox update_list;
    private Drivers? driver_proxy;

    public DriversView () {
        Object (
            icon: new ThemedIcon ("application-x-firmware"),
            title: _("Drivers"),
            description: _("Firmware updates provided by device manufacturers can improve performance and fix critical security issues.")
        );
    }

    construct {
        var none_placeholder = new Granite.Placeholder (_("No drivers available")) {
            description = _("No drivers available."),
            icon = new ThemedIcon ("emblem-default")
        };

        var checking_placeholder = new Granite.Placeholder (_("Checking for Updates")) {
            description = _("Connecting to the firmware service and searching for updates."),
            icon = new ThemedIcon ("sync-synchronizing")
        };

        update_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        update_list.set_placeholder (checking_placeholder);
        update_list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        var scrolled = new Gtk.ScrolledWindow () {
            child = update_list
        };

        var progress_placeholder = new Granite.Placeholder ("") {
            description = _("Do not unplug the device during the update."),
            icon = new ThemedIcon ("emblem-synchronized")
        };

        var error_placeholder = new Granite.Placeholder ("An error occured") {
            description = _("Oh no!!!"),
            icon = new ThemedIcon ("dialog-error")
        };

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };
        stack.add_named (none_placeholder, "none");
        stack.add_named (scrolled, "scrolled");
        stack.add_named (progress_placeholder, "progress");
        stack.add_named (error_placeholder, "error");

        var frame = new Gtk.Frame (null) {
            child = stack
        };

        child = frame;

        Bus.get_proxy.begin<Drivers> (SESSION, "io.elementary.settings-daemon", "/io/elementary/settings_daemon", 0, null, (obj, res) => {
            try {
                driver_proxy = Bus.get_proxy.end (res);

                driver_proxy.state_changed.connect (update_state);
                update_state.begin ();
            } catch (Error e) {
                critical ("Failed to get driver proxy: %s", e.message);
            }
        });
    }

    private async void update_state () {
        if (driver_proxy == null) {
            return;
        }

        Drivers.CurrentState current_state;
        try {
            current_state = yield driver_proxy.get_current_state ();
        } catch (Error e) {
            critical ("Failed to get current state from Updates Backend: %s", e.message);
            return;
        }

        stack.visible_child_name = current_state.state == DOWNLOADING ? "progress" : "scrolled";

        switch (current_state.state) {
            case UP_TO_DATE:
                stack.visible_child_name = "none";
                break;

            case CHECKING:
                //FIXME: Replace with remove_all
                while (update_list.get_row_at_index (0) != null) {
                    update_list.remove (update_list.get_row_at_index (0));
                }

                break;

            case AVAILABLE:
                //FIXME: Replace with remove_all
                while (update_list.get_row_at_index (0) != null) {
                    update_list.remove (update_list.get_row_at_index (0));
                }

                try {
                    var drivers = yield driver_proxy.get_available_drivers ();
                    foreach (var driver in drivers.get_keys ()) {
                        var row = new DriverRow (driver, drivers[driver]);
                        row.install.connect (() => driver_proxy.install.begin (row.driver_name));
                        update_list.append (row);
                    }
                } catch (Error e) {
                    warning ("Failed to get driver list from backend: %s", e.message);
                }

                break;

            case ERROR:
                stack.visible_child_name = "error";
                break;

            default:
                break;
        }
    }
}
