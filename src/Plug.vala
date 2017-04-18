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

    private string os;
    private string gtk_version;
    private string kernel_version;
    private string website_url;
    private string bugtracker_url;
    private string support_url;
    private string arch;
    private string processor;
    private string memory;
    private string graphics;
    private string hdd;
    private Gtk.Label based_off;


    private string upstream_release;
    private Gtk.Grid main_grid;

    public Plug () {
        Object (category: Category.SYSTEM,
                code_name: "system-pantheon-about",
                display_name: _("About"),
                description: _("View operating system and hardware information"),
                icon: "dialog-information");
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            setup_info ();
            setup_ui ();
        }

        return main_grid;
    }

    public override void shown () {
        main_grid.show ();
    }

    public override void hidden () {
        main_grid.hide ();

    }

    public override void search_callback (string location) {

    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("System Information")), "");
        search_results.set ("%s → %s".printf (display_name, _("Restore Default Settings")), "");
        search_results.set ("%s → %s".printf (display_name, _("Suggest Translation")), "");
        search_results.set ("%s → %s".printf (display_name, _("Report Problems")), "");
        search_results.set ("%s → %s".printf (display_name, _("Updates")), "");
        return search_results;
    }

    // Gets all the hardware info
    private void setup_info () {

        // Operating System

        File file = File.new_for_path("/etc/os-release");
        try {
            var osrel = new Gee.HashMap<string, string> ();
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                var osrel_component = line.split ("=", 2);
                if ( osrel_component.length == 2 ) {
                    osrel[osrel_component[0]] = osrel_component[1].replace ("\"", "");
                }
            }

            os = osrel["PRETTY_NAME"];
            website_url = osrel["HOME_URL"];
            bugtracker_url = osrel["BUG_REPORT_URL"];
            support_url = osrel["SUPPORT_URL"];
        } catch (Error e) {
            warning("Couldn't read os-release file, assuming elementary OS");
            os = "elementary OS";
            website_url = "https://elementary.io";
            bugtracker_url = "https://bugs.launchpad.net/elementaryos/+filebug";
            support_url = "https://elementary.io/support";

        }

        gtk_version = "%u.%u.%u".printf (Gtk.get_major_version (), Gtk.get_minor_version (), Gtk.get_micro_version ());

        //Upstream distro version (for "Built on" text)
        //FIXME: Add distro specific field to /etc/os-release and use that instead
        // Like "ELEMENTARY_UPSTREAM_DISTRO_NAME" or something
        file = File.new_for_path("/etc/upstream-release/lsb-release");
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                if ("DISTRIB_DESCRIPTION=" in line) {
                    upstream_release = line.replace ("DISTRIB_DESCRIPTION=", "");
                }
            }
        } catch (Error e) {
            warning("Couldn't read upstream lsb-release file, assuming none");
            upstream_release = null;
        }

        // Architecture
        Posix.UtsName uts_name;
        Posix.UtsName.get_default (out uts_name);
        switch (uts_name.machine) {
            case "x86_64":
                arch = "64-bit";
                break;
            case "arm":
                arch = "ARM";
                break;
            default:
                arch = "32-bit";
                break;
        }

        kernel_version = "%s %s".printf (uts_name.sysname, uts_name.release);

        // Processor
        var cpu_file = File.new_for_path ("/proc/cpuinfo");
        uint cores = 0U;
        try {
            var dis = new DataInputStream (cpu_file.read ());
            string line;
            while ((line = dis.read_line ()) != null) {
                if (line.has_prefix ("model name")) {
                    cores++;
                    if (processor == null) {
                        var parts = line.split (":", 2);
                        if (parts.length > 1) {
                            processor = parts[1].strip ();
                        }
                    }
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        if (processor == null) {
            processor = _("Unknown");
        } else {
            if ("(R)" in processor) {
                processor = processor.replace ("(R)", "®");
            }

            if ("(TM)" in processor) {
                processor = processor.replace ("(TM)", "™");
            }

            if (cores > 1) {
                if (cores == 2) {
                    processor = _("Dual-Core") + " " + processor;
                } else if (cores == 4) {
                    processor = _("Quad-Core") + " " + processor;
                } else {
                    processor = processor + " × " + cores.to_string ();
                }
            }
        }

        //Memory
        memory = GLib.format_size (get_mem_info ());

        // Graphics
        try {
            Process.spawn_command_line_sync ("lspci", out graphics);
            if ("VGA" in graphics) { //VGA-keyword indicates graphics-line
                string[] lines = graphics.split("\n");
                graphics="";
                foreach (var s in lines) {
                    if ("VGA" in s || "3D" in s) {
                        string model = get_graphics_from_string(s);
                        if(graphics=="")
                            graphics = model;
                        else
                            graphics += "\n" + model;
                    }
                }
            }
        } catch (Error e) {
            warning (e.message);
            graphics = _("Unknown");
        }

        // Hard Drive

        var file_root = GLib.File.new_for_path ("/");
        try {
            var info = file_root.query_filesystem_info (GLib.FileAttribute.FILESYSTEM_SIZE, null);
            hdd = GLib.format_size (info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE));
        } catch (Error e) {
            critical (e.message);
            hdd = _("Unknown");
        }
    }

    private string get_graphics_from_string(string graphics) {
        //at this line we have the correct line of lspci
        //as the line has now the form of "00:01.0 VGA compatible controller:Info"
        //and we want the <Info> part, we split with ":" and get the 3rd part
        string[] parts = graphics.split(":");
        string result = graphics;
        if (parts.length == 3)
            result = parts[2];
        else if (parts.length > 3) {
            result = parts[2];
            for (int i = 2; i < parts.length; i++) {
                result+=parts[i];
            }
        }
        else {
            warning("Unknown lspci format: "+parts[0]+parts[1]);
            result = _("Unknown"); //set back to unkown
        }
        return result.strip ();
    }

    // Wires up and configures initial UI
    private void setup_ui () {
        // Create the section about elementary OS
        var logo = new Gtk.Image.from_icon_name ("distributor-logo", Gtk.icon_size_register ("LOGO", 128, 128));
        logo.hexpand = true;

        var title = new Gtk.Label (os);
        title.get_style_context ().add_class ("h2");
        title.set_selectable (true);
        title.xalign = 1;

        var arch_name = new Gtk.Label ("(%s)".printf (arch));
        arch_name.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        arch_name.xalign = 0;

        if (upstream_release != null) {
            based_off = new Gtk.Label (_("Built on %s").printf (upstream_release));
            based_off.set_selectable (true);
        }
        
        var kernel_version_label = new Gtk.Label (kernel_version);
        kernel_version_label.set_selectable (true);

        var gtk_version_label = new Gtk.Label (_("GTK+ %s").printf (gtk_version));        
        gtk_version_label.set_selectable (true);

        var website_label = new Gtk.LinkButton.with_label (website_url, _("Website"));
        website_label.halign = Gtk.Align.CENTER;
        website_label.margin_top = 12;

        var processor_info = new Gtk.Label (processor);
        processor_info.margin_top = 12;
        processor_info.set_selectable (true);

        var memory_info = new Gtk.Label (_("%s memory").printf (memory));
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.set_selectable (true);

        var hdd_info = new Gtk.Label (_("%s storage").printf (hdd));
        hdd_info.set_selectable (true);

        var help_button = new Gtk.Button.with_label ("?");
        help_button.get_style_context ().add_class ("circular");
        help_button.halign = Gtk.Align.END;

        help_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (support_url, null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        help_button.size_allocate.connect ( (alloc) => {
            help_button.set_size_request (alloc.height, -1);
        });

        // Translate button
        var translate_button = new Gtk.Button.with_label (_("Suggest Translations"));
        translate_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://l10n.elementary.io/projects/", null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        // Bug button
        var bug_button = new Gtk.Button.with_label (_("Report a Problem"));
        bug_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (bugtracker_url, null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        // Update button
        var update_button = new Gtk.Button.with_label (_("Check for Updates"));
        update_button.clicked.connect (() => {
            try {
                Process.spawn_command_line_async("appcenter --show-updates");
            } catch (Error e) {
                warning (e.message);
            }
        });

        // Restore settings button
        var settings_restore_button = new Gtk.Button.with_label (_("Restore Default Settings"));
        settings_restore_button.clicked.connect (settings_restore_clicked);

        // Create a box for the buttons
        var button_grid = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_grid.halign = Gtk.Align.CENTER;
        button_grid.spacing = 6;
        button_grid.add (help_button);
        button_grid.add (settings_restore_button);
        button_grid.add (translate_button);
        button_grid.add (bug_button);
        button_grid.add (update_button);
        button_grid.set_child_non_homogeneous (help_button, true);

        var software_grid = new Gtk.Grid ();
        software_grid.column_spacing = 6;
        software_grid.row_spacing = 6;
        software_grid.attach (logo, 0, 0, 2, 1);
        software_grid.attach (title, 0, 1, 1, 1);
        software_grid.attach (arch_name, 1, 1, 1, 1);

        if (upstream_release != null) {
            software_grid.attach (based_off, 0, 2, 2, 1);
        }

        software_grid.attach (kernel_version_label, 0, 3, 2, 1);        
        software_grid.attach (gtk_version_label, 0, 4, 2, 1);
        software_grid.attach (website_label, 0, 5, 2, 1);

        var manufacturer_logo = new Gtk.Image ();
        manufacturer_logo.pixel_size = 128;
        manufacturer_logo.icon_name = "computer";

        var hardware_grid = new Gtk.Grid ();
        hardware_grid.column_spacing = 6;
        hardware_grid.row_spacing = 6;
        hardware_grid.attach (manufacturer_logo, 0, 0, 2, 1);
        hardware_grid.attach (processor_info, 0, 3, 2, 1);
        hardware_grid.attach (graphics_info, 0, 4, 2, 1);
        hardware_grid.attach (memory_info, 0, 5, 2, 1);
        hardware_grid.attach (hdd_info, 0, 6, 2, 1);

        var description_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        description_size_group.add_widget (hardware_grid);
        description_size_group.add_widget (software_grid);

        var description_grid = new Gtk.Grid ();
        description_grid.halign = Gtk.Align.CENTER;
        description_grid.valign = Gtk.Align.CENTER;
        description_grid.vexpand = true;
        description_grid.column_spacing = 24;
        description_grid.add (software_grid);
        description_grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        description_grid.add (hardware_grid);

        main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.row_spacing = 12;
        main_grid.margin = 12;
        main_grid.add (description_grid);
        main_grid.add (button_grid);
        main_grid.show_all ();
    }
}

private uint64 get_mem_info () {
    File file = File.new_for_path ("/proc/meminfo");
    try {
        DataInputStream dis = new DataInputStream (file.read ());
        string? line;
        string name = "MemTotal:";
        while ((line = dis.read_line (null,null)) != null) {
            if (line.has_prefix (name)) {
                var number = line.replace ("kB", "").replace (name, "").strip ();
                return uint64.parse (number) * 1000;
            }
        }
    } catch (Error e) {
        warning (e.message);
    }

    return 0;
}

private void reset_all_keys (GLib.Settings settings) {
    var keys = settings.list_keys ();
    foreach (var key in keys) {
        settings.reset (key);
    }
}

private string[] get_pantheon_schemas () {
    string[] schemas = {};
    string[] pantheon_schemas = {};
    string[] prefixes = { "org.pantheon.desktop", "org.gnome.desktop" };

    var sss = SettingsSchemaSource.get_default ();

    sss.list_schemas (true, out schemas, null);

    foreach (var schema in schemas) {
        foreach (var prefix in prefixes) {
            if (schema.has_prefix (prefix)) {
                pantheon_schemas += schema;
            }
        }
    }
    return pantheon_schemas;
}

private void reset_recursively (string schema) {
    var settings = new GLib.Settings (schema);
    // change into delay mode
	// so changes take place when apply () is called
    settings.delay ();

    reset_all_keys (settings);

    var children = settings.list_children ();
    foreach (var child in children) {
        var child_settings = settings.get_child (child);

        reset_all_keys (child_settings);
    }
    settings.apply ();
    GLib.Settings.sync ();
}

/**
 * returns true to continue, false to cancel
 */
private bool confirm_restore_action () {
    var dialog = new RestoreDialog ();
    dialog.show_all ();

    var result = dialog.run ();
    dialog.destroy ();

    if (result == 1) {
        // continue was clicked
        return true;
    } else {
        // cancel was clicked
        return false;
    }
}

private void settings_restore_clicked () {
    var should_display = confirm_restore_action ();

    if (should_display) {
        var all_schemas = get_pantheon_schemas ();

        foreach (var schema in all_schemas) {
            reset_recursively (schema);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating About plug");
    var plug = new About.Plug ();
    return plug;
}
