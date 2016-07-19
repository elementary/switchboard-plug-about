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
    private string website_url;
    private string bugtracker_url;
    private string codename;
    private string version;
    private string arch;
    private string processor;
    private string memory;
    private string graphics;
    private string hdd;
    private Gtk.Label based_off;


    private string is_ubuntu;
    private string ubuntu_version;
    private string ubuntu_codename;
    private Gtk.EventBox main_grid;

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
        search_results.set ("%s → %s".printf (display_name, _("Report Problems")), "");
        search_results.set ("%s → %s".printf (display_name, _("Updates")), "");
        return search_results;
    }

    private string capitalize (string str) {
        var result_builder = new StringBuilder ("");

        weak string i = str;

        bool first = true;
        while (i.length > 0) {
            unichar c = i.get_char ();
            if (first) {
                result_builder.append_unichar (c.toupper ());
                first = false;
            } else {
                result_builder.append_unichar (c);
            }

            i = i.next_char ();
        }

        return result_builder.str;
    }

    // Gets all the hardware info
    private void setup_info () {

        // Operating System

        File file = File.new_for_path("/etc/lsb-release");
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                if ("DISTRIB_DESCRIPTION=" in line) {
                    os = line.replace ("DISTRIB_DESCRIPTION=", "");
                    if ("\"" in os) {
                        os = os.replace ("\"", "");
                    }
                } else if ("DISTRIB_RELEASE=" in line) {
                    version = line.replace ("DISTRIB_RELEASE=", "");
                } else if ("DISTRIB_CODENAME=" in line) {
                    codename = line.replace ("DISTRIB_CODENAME=", "");
                    codename = capitalize (codename);
                }
            }
        } catch (Error e) {
            warning("Couldn't read lsb-release file, assuming elementary OS 0.3");
            os = "elementary OS";
            version = "0.3";
            codename = "Freya";
        }

        file = File.new_for_path("/etc/upstream-release/lsb-release");
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                if ("DISTRIB_ID=" in line) {
                    is_ubuntu = line.replace ("DISTRIB_ID=", "");
                } else if ("DISTRIB_RELEASE=" in line) {
                    ubuntu_version = line.replace ("DISTRIB_RELEASE=", "");
                } else if ("DISTRIB_CODENAME=" in line) {
                    ubuntu_codename = line.replace ("DISTRIB_CODENAME=", "");
                    ubuntu_codename = capitalize (ubuntu_codename);
                }
            }
        } catch (Error e) {
            warning("Couldn't read upstream lsb-release file, assuming none");
            is_ubuntu = null;
            ubuntu_version = null;
            ubuntu_codename = null;
        }

        //Bugtracker and website
        file = File.new_for_path("/etc/dpkg/origins/"+os);
        bugtracker_url = "";
        website_url = "";
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                if (line.has_prefix("Bugs:")) {
                    bugtracker_url = line.replace ("Bugs: ", "");
                }
            }
        } catch (Error e) {
            warning(e.message);
            warning("Couldn't find bugtracker/website, using elementary OS defaults");
            if (website_url == "")
                website_url = "http://elementary.io";
            if (bugtracker_url == "")
                bugtracker_url = "https://bugs.launchpad.net/elementaryos/+filebug";
        }

        // Architecture
        try {
            Process.spawn_command_line_sync ("uname -m", out arch);
            if (arch == "x86_64\n") {
                arch = "64-bit";
            } else if ("arm" in arch) {
                arch = "ARM";
            } else {
                arch = "32-bit";
            }
        } catch (Error e) {
            warning (e.message);
            arch = _("Unknown");
        }

        // Processor
        try {
            Process.spawn_command_line_sync ("sed -n 's/^model name[ \t]*: *//p' /proc/cpuinfo", out processor);
            int cores = 0;
            foreach (string core in processor.split ("\n")) {
                if (core != "") {
                    cores++;
                }
            }
            if ("\n" in processor) {
                processor = processor.split ("\n")[0];
            } if ("(R)" in processor) {
                processor = processor.replace ("(R)", "®");
            } if ("(TM)" in processor) {
                processor = processor.replace ("(TM)", "™");
            } if (cores > 1) {
                if (cores == 2) {
                    processor = _("Dual-Core") + " " + processor;
                } else if (cores == 4) {
                    processor = _("Quad-Core") + " " + processor;
                } else {
                    processor = processor + " × " + cores.to_string ();
                }
            }
        } catch (Error e) {
            warning (e.message);
            processor = _("Unknown");
        }

        //Memory
        memory = GLib.format_size (get_mem_info_for("MemTotal:") * 1024, FormatSizeFlags.IEC_UNITS);

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
        main_grid = new Gtk.EventBox ();

        // Create the section about elementary OS
        var logo = new Gtk.Image.from_icon_name ("distributor-logo", Gtk.icon_size_register ("LOGO", 128, 128));
        logo.halign = Gtk.Align.END;

        var title = new Gtk.Label (null);
        title.set_markup (("%s %s %s <sup><small>(%s)</small></sup>").printf (os, version, codename, arch));
        title.get_style_context ().add_class ("h2");
        title.halign = Gtk.Align.START;
        title.set_selectable (true);

        if (is_ubuntu != null) {
            based_off = new Gtk.Label (_("Built on %s %s").printf (is_ubuntu, ubuntu_version));
            based_off.halign = Gtk.Align.START;
            based_off.set_selectable (true);
        }

        var website_label = new Gtk.LinkButton.with_label ("http://elementary.io", _("Website"));
        website_label.halign = Gtk.Align.START;

        var hardware_title = new Gtk.Label (null);
        hardware_title.set_label (_("Hardware"));
        hardware_title.get_style_context ().add_class ("h3");
        hardware_title.halign = Gtk.Align.END;
        hardware_title.margin_top = 24;

        var processor_label = new Gtk.Label (_("Processor:"));
        processor_label.halign = Gtk.Align.END;

        var memory_label = new Gtk.Label (_("Memory:"));
        memory_label.halign = Gtk.Align.END;

        var graphics_label = new Gtk.Label (_("Graphics:"));
        graphics_label.halign = Gtk.Align.END;

        var hdd_label = new Gtk.Label (_("Storage:"));
        hdd_label.halign = Gtk.Align.END;

        var processor_info = new Gtk.Label (processor);
        processor_info.halign = Gtk.Align.START;
        processor_info.set_selectable (true);
        processor_info.set_line_wrap (false);

        var memory_info = new Gtk.Label (memory);
        memory_info.halign = Gtk.Align.START;
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.halign = Gtk.Align.START;
        graphics_info.set_selectable (true);
        graphics_info.set_line_wrap (false);

        var hdd_info = new Gtk.Label (hdd);
        hdd_info.halign = Gtk.Align.START;
        hdd_info.set_selectable (true);

        var help_button = new Gtk.Button.with_label ("?");
        help_button.get_style_context ().add_class ("circular");

        help_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("http://elementary.io/support", null);
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
                AppInfo.launch_default_for_uri ("https://translations.launchpad.net/elementary", null);
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
        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.spacing = 6;
        button_box.pack_start (help_button, false, false, 0);
        button_box.set_child_non_homogeneous (help_button, true);
        button_box.pack_end (settings_restore_button, false, false, 0);
        button_box.pack_end (translate_button, false, false, 0);
        button_box.pack_end (bug_button, false, false, 0);
        button_box.pack_end (update_button, false, false, 0);

        // Fit everything in a box
        var layout = new Gtk.Grid ();
        layout.column_spacing = 6;
        layout.row_spacing = 6;

        layout.attach (logo, 0, 0, 1, 3);
        layout.attach (title, 1, 0, 1, 1);
        layout.attach (based_off, 1, 1, 1, 1);
        layout.attach (website_label, 1, 2, 1, 1);

        layout.attach (hardware_title, 0, 3, 1, 1);
        layout.attach (processor_label, 0, 4, 1, 1);
        layout.attach (processor_info, 1, 4, 1, 1);
        layout.attach (memory_label, 0, 5, 1, 1);
        layout.attach (memory_info, 1, 5, 1, 1);
        layout.attach (graphics_label, 0, 6, 1, 1);
        layout.attach (graphics_info, 1, 6, 1, 1);
        layout.attach (hdd_label, 0, 7, 1, 1);
        layout.attach (hdd_info, 1, 7, 1, 1);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24);
        box.pack_start (layout, false, false, 0);
        box.pack_end (button_box, false, false, 0);
        box.set_margin_top (24);
        box.set_margin_bottom (24);

        // Let's align the box and add it to the plug
        var halign = new Gtk.Alignment ((float) 0.5, 0, 0, 1);
        halign.add (box);
        main_grid.add (halign);
        main_grid.show_all ();
    }
}

private uint64 get_mem_info_for(string name) {
    uint64 result = 0;
    File file = File.new_for_path ("/proc/meminfo");
    try {
        DataInputStream dis = new DataInputStream (file.read());
        string? line;
        while ((line = dis.read_line (null,null)) != null) {
            if(line.has_prefix(name)) {
                //get the kb-part of the string with witespaces
                line = line.substring(name.length,
                                      line.last_index_of("kB")-name.length);
                result = uint64.parse(line.strip());
                break;
            }
        }
    } catch (Error e) {
        warning (e.message);
    }

    return result;
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
    var dialog = new Gtk.Dialog ();

    Gtk.Box box = dialog.get_content_area () as Gtk.Box;
    var layout = new Gtk.Grid ();
    var text = new Gtk.Label ("");

    text.set_markup ("<span weight='bold' size='larger'>" +
                     _("System settings will be restored to the factory defaults") + "</span>\n\n"+
                     _("All system settings and data will be reset to the default values.") + "\n" +
                     _("Personal data, such as music and pictures, will be uneffected."));

    var image = new Gtk.Image.from_icon_name ("dialog-warning",
                                              Gtk.IconSize.DIALOG);
    image.yalign = 0;
    image.show ();

    layout.set_column_spacing (12);
    layout.set_margin_right (6);
    layout.set_margin_bottom (18);
    layout.set_margin_left (6);

    layout.add (image);
    layout.add (text);

    box.pack_start (layout);

    var continue_button = new Gtk.Button.with_label (_("Restore Settings"));
    continue_button.get_style_context ().add_class ("destructive-action");

    var cancel_button = new Gtk.Button.with_label (_("Cancel"));
    continue_button.show ();
    cancel_button.show ();

    dialog.border_width = 6;
    dialog.deletable = false;
    dialog.add_action_widget (cancel_button, 0);
    dialog.add_action_widget (continue_button, 1);

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
