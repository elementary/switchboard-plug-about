/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
*           2015 Ivo Nunes, Akshay Shekher
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
*/

public class About.Plug : Switchboard.Plug {
    private Gtk.Grid main_grid;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("about", null);
        Object (category: Category.SYSTEM,
                code_name: "io.elementary.switchboard.about",
                display_name: _("System"),
                description: _("View operating system and hardware information"),
                icon: "application-x-firmware",
                supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            var operating_system_view = new OperatingSystemView ();

            var hardware_view = new HardwareView () {
                valign = Gtk.Align.CENTER
            };

            var firmware_view = new FirmwareView ();

            var stack = new Gtk.Stack () {
                vexpand = true
            };
            stack.add_titled (operating_system_view, "operating-system-view", _("Operating System"));
            stack.add_titled (hardware_view, "hardware-view", _("Hardware"));
            stack.add_titled (firmware_view, "firmware-view", _("Firmware"));

            var stack_switcher = new Gtk.StackSwitcher () {
                halign = Gtk.Align.CENTER,
                homogeneous = true,
                margin_top = 24,
                stack = stack
            };

            main_grid = new Gtk.Grid () {
                row_spacing = 12
            };
            main_grid.attach (stack_switcher, 0, 0);
            main_grid.attach (stack, 0, 1);
            main_grid.show_all ();
        }

        return main_grid;
    }

    public override void shown () {
    }

    public override void hidden () {
    }

    public override void search_callback (string location) {
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("System Information")), "");
        search_results.set ("%s → %s".printf (display_name, _("Restore Default Settings")), "");
        search_results.set ("%s → %s".printf (display_name, _("Suggest Translation")), "");
        search_results.set ("%s → %s".printf (display_name, _("Send Feedback")), "");
        search_results.set ("%s → %s".printf (display_name, _("Report a Problem")), "");
        search_results.set ("%s → %s".printf (display_name, _("Updates")), "");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating System plug");
    var plug = new About.Plug ();
    return plug;
}
