//
//  Copyright (C) 2015 Ivo Nunes, Akshay Shekher
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public class About.Plug : Switchboard.Plug {
    private Gtk.Stack stack;
    private OperatingSystemView operating_system_view;
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
            main_grid = new Gtk.Grid ();

            stack = new Gtk.Stack ();

            operating_system_view = new OperatingSystemView ();
            stack.add_titled (operating_system_view, "os", _("Operating System"));

            var hardware_view = new HardwareView ();
            stack.add_titled (hardware_view, "hardware", _("Hardware"));

            var firmware_view = new FirmwareView ();
            stack.add_titled (firmware_view, "firmware", _("Firmware"));

            var stack_switcher = new Gtk.StackSwitcher () {
                halign = Gtk.Align.CENTER,
                homogeneous = true,
                margin = 24,
                stack = stack
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
