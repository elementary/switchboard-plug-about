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
    private string support_url;
    private string arch;
    private Gtk.Label based_off;

    private string upstream_release;
    private Gtk.Grid main_grid;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("about", null);
        Object (category: Category.SYSTEM,
                code_name: "system-pantheon-about",
                display_name: _("About"),
                description: _("View operating system and hardware information"),
                icon: "dialog-information",
                supported_settings: settings);
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

    private void setup_info () {

        // Operating System
        var file = File.new_for_path ("/etc/os-release");
        try {
            var osrel = new Gee.HashMap<string, string> ();
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                var osrel_component = line.split ("=", 2);
                if (osrel_component.length == 2) {
                    osrel[osrel_component[0]] = osrel_component[1].replace ("\"", "");
                }
            }

            os = osrel["PRETTY_NAME"];
            website_url = osrel["HOME_URL"];
            support_url = osrel["SUPPORT_URL"];
        } catch (Error e) {
            warning ("Couldn't read os-release file, assuming elementary OS");
            os = "elementary OS";
            website_url = "https://elementary.io";
            support_url = "https://elementary.io/support";
        }

        gtk_version = "%u.%u.%u".printf (Gtk.get_major_version (), Gtk.get_minor_version (), Gtk.get_micro_version ());

        // Upstream distro version (for "Built on" text)
        // FIXME: Add distro specific field to /etc/os-release and use that instead
        // Like "ELEMENTARY_UPSTREAM_DISTRO_NAME" or something
        file = File.new_for_path ("/etc/upstream-release/lsb-release");
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                var distrib_component = line.split ("=", 2);
                if (distrib_component.length == 2) {
                    upstream_release = distrib_component[1].replace ("\"", "");
                }
            }
        } catch (Error e) {
            warning ("Couldn't read upstream lsb-release file, assuming none");
            upstream_release = null;
        }

        // Architecture
        var uts_name = Posix.utsname ();
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
    }

    // Wires up and configures initial UI
    private void setup_ui () {
        // Create the section about elementary OS
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.hexpand = true;

        var title = new Gtk.Label (os);
        title.get_style_context ().add_class ("h2");
        title.set_selectable (true);
        title.margin_bottom = 12;
        title.ellipsize = Pango.EllipsizeMode.END;
        title.xalign = 1;

        var arch_name = new Gtk.Label ("(%s)".printf (arch));
        arch_name.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        arch_name.margin_bottom = 12;
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
            var issue_dialog = new IssueDialog ();
            issue_dialog.transient_for = (Gtk.Window) main_grid.get_toplevel ();
            issue_dialog.run ();
        });

        // Update button
        var update_button = new Gtk.Button.with_label (_("Check for Updates"));
        update_button.clicked.connect (() => {
            try {
                Process.spawn_command_line_async ("io.elementary.appcenter --show-updates");
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

        var hardware_view = new HardwareView ();

        var description_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        description_size_group.add_widget (hardware_view);
        description_size_group.add_widget (software_grid);

        var description_grid = new Gtk.Grid ();
        description_grid.halign = Gtk.Align.CENTER;
        description_grid.valign = Gtk.Align.CENTER;
        description_grid.vexpand = true;
        description_grid.column_spacing = 24;
        description_grid.margin_start = 12;
        description_grid.margin_end = 12;
        description_grid.add (software_grid);
        description_grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        description_grid.add (hardware_view);

        main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.row_spacing = 12;
        main_grid.margin = 12;
        main_grid.add (description_grid);
        main_grid.add (button_grid);
        main_grid.show_all ();
    }

     /**
     * returns true to continue, false to cancel
     */
    private bool confirm_restore_action () {
        var dialog = new RestoreDialog ();
        dialog.show_all ();

        var result = dialog.run ();
        dialog.destroy ();

        return result == 1;
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

    private static void reset_all_keys (GLib.Settings settings) {
        var keys = settings.list_keys ();
        foreach (var key in keys) {
            settings.reset (key);
        }
    }
    
    private static string[] get_pantheon_schemas () {
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
    
    private static void reset_recursively (string schema) {
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
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating About plug");
    var plug = new About.Plug ();
    return plug;
}
