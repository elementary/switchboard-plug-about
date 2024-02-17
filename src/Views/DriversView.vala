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
    private uint num_updates = 0;

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
    }

    private async void update_state () {
        if (driver_proxy == null) {
            return;
        }

        SystemUpdate.CurrentState current_state;
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
                update_list.remove_all ();
                break;
            case CHECKING:
                update_list.remove_all ();
                break;
            case AVAILABLE:
                try {
                    var drivers = yield driver_proxy.get_available_drivers ();
                    foreach (var driver in drivers.get_keys ()) {
                        update_list.append (new Gtk.Label (driver));
                    }
                } catch (Error e) {
                    warning ("Failed to get driver list from backend: %s", e.message);
                }
                break;
            case ERROR:
                stack.visible_child_name = "error";
                break;
        }
    }
}
