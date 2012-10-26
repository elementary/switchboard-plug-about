//  
//  Copyright (C) 2012 Ivo Nunes
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

// Main Class, acts pretty much like a Gtk.Window because it's a Gtk.Plug with some magic behind the scenes
public class AboutPlug : Pantheon.Switchboard.Plug {

    private string os;
    private string codename;
    private string version;
    private string arch;
    private string processor;
    private string memory;
    private string graphics;
    private string hdd;

    public AboutPlug () {
        setup_info ();
        setup_ui ();
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
                if ("DISTRIB_ID=" in line) {
                    os = line.replace ("DISTRIB_ID=", "");
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
            os = "elementary OS";
            version = "0.2";
            codename = "Luna";
        }

        // Architecture
        Process.spawn_command_line_sync ("uname -m", out arch);
        if (arch == "x86_64\n") {
            arch = "64 bits";
        } else if ("arm" in arch) {
            arch = "ARM";
        } else {
            arch = "32 bits";
        }

        // Processor
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
            processor = processor + " × " + cores.to_string ();
        }

        // Memory
        Process.spawn_command_line_sync ("""awk '/MemTotal/ {print $2 }' /proc/meminfo""", out memory);
        if ("\n" in memory) {
            memory = memory.replace ("\n", "");
        }
        memory = GLib.format_size (memory.to_uint64 () * 1000);

        // Graphics
        Process.spawn_command_line_sync ("lspci", out graphics);
        if ("VGA" in graphics) {
            graphics = graphics.split("VGA")[1];
            if (":" in graphics) {
                graphics = graphics.split (":")[1];
            } if ("[" in graphics) {
                graphics = graphics.split ("[")[1];
            } if ("]" in graphics) {
                graphics = graphics.split ("]")[0];
            } if ("(" in graphics) {
                graphics = graphics.split ("(")[0];
            } if ("Chipset" in graphics) {
                graphics = graphics.split ("Chipset")[0];
            }
        } else {
            graphics = "Unknown";
        }

        // Hard Drive
        Process.spawn_command_line_sync ("df -h", out hdd);
        foreach (string partition in hdd.split ("\n")) {
            if ("/\n" in partition + "\n") {
                hdd = partition;
            }
        }
        hdd = hdd.split ("G")[0];
        hdd = hdd.reverse ().split (" ")[0].reverse ();
        hdd = GLib.format_size (hdd.to_uint64 () * 1000000000);
    }

    // Wires up and configures initial UI
    private void setup_ui () {

        // Let's make sure this looks like the About dialogs
        this.get_style_context ().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

        // Create the section about elementary OS
        var logo = new Gtk.Image.from_icon_name ("distributor-logo", Gtk.icon_size_register ("LOGO", 100, 100));

        var title = new Gtk.Label (null);
        title.set_markup ("<span font=\"Raleway 36\">" + os + "</span>");
        title.set_alignment (0, 0);

        var version = new Gtk.Label (_("Version") + ": " + version + " \"" + codename + "\" (" + arch + ")");
        version.set_alignment (0, 0);
        version.set_selectable (true);

        var website_label = new Gtk.Label (null);
        website_label.set_markup ("<span foreground=\"blue\">http://elementaryos.org</span>");
        website_label.set_alignment (0, 0);
        var website = new Gtk.EventBox ();
        website.add (website_label);
        website.button_press_event.connect (() => { Process.spawn_command_line_async("x-www-browser http://elementaryos.org"); return true; });

        var details = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        details.pack_start (title, false, false, 0);
        details.pack_start (version, false, false, 0);
        details.pack_start (website, false, false, 0);

        var elementary_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        elementary_box.pack_start (logo, false, false, 0);
        elementary_box.pack_start (details, false, false, 0);

        // Hardware title 
        var hardware_title = new Gtk.Label (null);
        hardware_title.set_markup (("<b><span size=\"x-large\">%s</span></b>").printf(_("Hardware:")));
        hardware_title.set_alignment (0, 0);

        // Hardware labels
        var processor_label = new Gtk.Label (_("Processor:"));
        processor_label.set_alignment (1, 0);

        var memory_label = new Gtk.Label (_("Memory:"));
        memory_label.set_alignment (1, 0);

        var graphics_label = new Gtk.Label (_("Graphics:"));
        graphics_label.set_alignment (1, 0);

        var hdd_label = new Gtk.Label (_("Hard Drive:"));
        hdd_label.set_alignment (1, 0); 

        // Hardware info
        var processor_info = new Gtk.Label (processor);
        processor_info.set_alignment (0, 0);
        processor_info.set_margin_left (6);
        processor_info.set_selectable (true);

        var memory_info = new Gtk.Label (memory);
        memory_info.set_alignment (0, 0);
        memory_info.set_margin_left (6);
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.set_alignment (0, 0);
        graphics_info.set_margin_left (6);
        graphics_info.set_selectable (true);

        var hdd_info = new Gtk.Label (hdd);
        hdd_info.set_alignment (0, 0);
        hdd_info.set_margin_left (6);
        hdd_info.set_selectable (true);

        // Hardware grid
        var hardware_grid = new Gtk.Grid ();
        hardware_grid.set_row_spacing (1);
        hardware_grid.attach (hardware_title, 0, 0, 100, 30);
        hardware_grid.attach (processor_label, 0, 40, 100, 25);
        hardware_grid.attach (memory_label, 0, 80, 100, 25);
        hardware_grid.attach (graphics_label, 0, 120, 100, 25);
        hardware_grid.attach (hdd_label, 0, 160, 100, 25);
        hardware_grid.attach (processor_info, 100, 40, 100, 25);
        hardware_grid.attach (memory_info, 100, 80, 100, 25);
        hardware_grid.attach (graphics_info, 100, 120, 100, 25);
        hardware_grid.attach (hdd_info, 100, 160, 100, 25);

        // Help button
        const string HELP_BUTTON_STYLESHEET = """
            .help_button {
                border-radius: 200px;
            }
        """;

        var help_button = new Gtk.Button.with_label ("?");

        Granite.Widgets.Utils.set_theming (help_button, HELP_BUTTON_STYLESHEET, "help_button",
                           Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        help_button.clicked.connect (() => { Process.spawn_command_line_async("x-www-browser http://elementaryos.org/support/answers"); });

        help_button.size_allocate.connect ( (alloc) => {
            help_button.set_size_request (alloc.height, -1);
        });

        // Translate button
        var translate_button = new Gtk.Button.with_label (_("Translate"));
        translate_button.clicked.connect (() => { Process.spawn_command_line_async("x-www-browser https://translations.launchpad.net/elementary"); });

        // Bug button
        var bug_button = new Gtk.Button.with_label (_("Report a Problem"));
        bug_button.clicked.connect (() => { Process.spawn_command_line_async("x-www-browser https://bugs.launchpad.net/elementary/+filebug"); });

        // Upgrade button
        var upgrade_button = new Gtk.Button.with_label (_("Check for Upgrades"));
        upgrade_button.clicked.connect (() => { Process.spawn_command_line_async("update-manager"); });

        // Create a box for the buttons
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        button_box.pack_start (help_button, false, false, 0);
        button_box.pack_start (translate_button, true, true, 0);
        button_box.pack_start (bug_button, true, true, 0);
        button_box.pack_start (upgrade_button, true, true, 0);

        // Fit everything in a box
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        box.pack_start (elementary_box, false, false, 25);
        box.pack_start (hardware_grid, false, false, 50);
        box.pack_end (button_box, false, false, 0);

        // Let's align the box and add it to the plug
        var halign = new Gtk.Alignment ((float) 0.5, 0, 0, 0);
        halign.add (box);
        this.add (halign);
    }
}

public static int main (string[] args) {

    Gtk.init (ref args);
    // Instantiate the plug, which handles
    // connecting to Switchboard.
    var plug = new AboutPlug ();
    // Connect to Switchboard and identify
    // as "About". (For debugging)
    plug.register ("About");
    plug.show_all ();
    // Start the GTK+ main loop.
    Gtk.main ();
    return 0;
}
