/*
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
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

public class About.HardwareView : Gtk.Grid {
    private bool oem_enabled;
    private string graphics;
    private string hdd;
    private string manufacturer_icon_path;
    private string manufacturer_name;
    private string manufacturer_support_url;
    private string memory;
    private string processor;
    private string product_name;
    private string product_version;

    private const string LAPTOP_DETECT_NAME = "laptop-detect";

    construct {
        fetch_hardware_info ();

        var manufacturer_logo = new Gtk.Image ();
        manufacturer_logo.pixel_size = 128;

        if (laptop_detect ()) {
            manufacturer_logo.icon_name = "computer-notebook";
        } else {
            manufacturer_logo.icon_name = "computer";
        }

        var product_name_info = new Gtk.Label (Environment.get_host_name ());
        product_name_info.get_style_context ().add_class ("h2");
        product_name_info.set_selectable (true);

        var processor_info = new Gtk.Label (processor);
        processor_info.margin_top = 12;
        processor_info.set_selectable (true);

        var memory_info = new Gtk.Label (_("%s memory").printf (memory));
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.set_selectable (true);

        var hdd_info = new Gtk.Label (_("%s storage").printf (hdd));
        hdd_info.set_selectable (true);

        column_spacing = 6;
        row_spacing = 6;
        attach (manufacturer_logo, 0, 0, 2, 1);
        attach (processor_info, 0, 3, 2, 1);
        attach (graphics_info, 0, 4, 2, 1);
        attach (memory_info, 0, 5, 2, 1);
        attach (hdd_info, 0, 6, 2, 1);

        if (oem_enabled) {
            var fileicon = new FileIcon (File.new_for_path (manufacturer_icon_path));

            if (manufacturer_icon_path != null) {
                manufacturer_logo.icon_name = null;
                manufacturer_logo.gicon = fileicon;
            }

            var manufacturer_info = new Gtk.Label (manufacturer_name);
            manufacturer_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            manufacturer_info.set_selectable (true);

            attach (manufacturer_info, 0, 2, 2, 1);

            if (product_name != null) {
                product_name_info.label = product_name;
                product_name_info.xalign = 1;
            }

            if (product_version != null) {
                var product_version_info = new Gtk.Label ("(" + product_version + ")");
                product_version_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
                product_version_info.set_selectable (true);
                product_version_info.xalign = 0;
                attach (product_name_info, 0, 1, 1, 1);
                attach (product_version_info, 1, 1, 1, 1);
            } else {
                attach (product_name_info, 0, 1, 2, 1);
            }

            if (manufacturer_support_url != null) {
                var manufacturer_website_info = new Gtk.LinkButton.with_label (manufacturer_support_url, _("Manufacturer Website"));
                attach (manufacturer_website_info, 0, 7, 2, 1);
            }
        } else {
            attach (product_name_info, 0, 1, 2, 1);
        }
    }

    private void fetch_hardware_info () {
        // Processor
        var cpu_file = File.new_for_path ("/proc/cpuinfo");
        uint cores = 0U;
        bool cores_found = false;
        try {
            var dis = new DataInputStream (cpu_file.read ());
            string line;
            while ((line = dis.read_line ()) != null) {
                if (line.has_prefix ("cpu cores")) {
                    var core_count = line.split (":", 2);
                    if (core_count.length > 1) {
                        cores = int.parse (core_count[1]);
                        if (cores != 0) {
                            cores_found = true;
                        }
                    }
                }

                if (line.has_prefix ("model name")) {
                    if (!cores_found) {
                        cores++;
                    }
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

                        if (graphics=="") {
                            graphics = model;
                        } else {
                            graphics += "\n" + model;
                        }
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

        try {
            var oem_file = new KeyFile ();
            oem_file.load_from_file ("/etc/oem.conf", KeyFileFlags.NONE);
            // Assume we get the manufacturer name
            manufacturer_name = oem_file.get_string ("OEM", "Manufacturer");

            // We need to check if the key is here because get_string throws an error if the key isn't available.
            if (oem_file.has_key ("OEM", "Product")) {
                product_name = oem_file.get_string ("OEM", "Product");
            }

            if (oem_file.has_key ("OEM", "Version")) {
                product_version = oem_file.get_string ("OEM", "Version");
            }

            if (oem_file.has_key ("OEM", "Logo")) {
                manufacturer_icon_path = oem_file.get_string ("OEM", "Logo");
            }

            if (oem_file.has_key ("OEM", "URL")) {
                manufacturer_support_url = oem_file.get_string ("OEM", "URL");
            }

            oem_enabled = true;
        } catch (Error e) {
            debug (e.message);
            oem_enabled = false;
        }
    }

    private string get_graphics_from_string(string graphics) {
        //at this line we have the correct line of lspci
        //as the line has now the form of "00:01.0 VGA compatible controller:Info"
        //and we want the <Info> part, we split with ":" and get the 3rd part
        string[] parts = graphics.split(":");
        string result = graphics;
        if (parts.length == 3) {
            result = parts[2];
        } else if (parts.length > 3) {
            result = parts[2];
            for (int i = 2; i < parts.length; i++) {
                result+=parts[i];
            }
        } else {
            warning("Unknown lspci format: "+parts[0]+parts[1]);
            result = _("Unknown"); //set back to unkown
        }
        return result.strip ();
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

    private static bool laptop_detect () {
        string? laptop_detect_executable = Environment.find_program_in_path (LAPTOP_DETECT_NAME);
        if (laptop_detect_executable == null) {
            warning ("laptop-detect not found");
            return false;
        }

        int exit_status;

        try {
            Process.spawn_command_line_sync (laptop_detect_executable, null, null, out exit_status);
            if (exit_status == 0) {
                debug ("Detected a laptop");
                return true;
            }
        } catch (SpawnError err) {
            warning (err.message);
        }

        return false;
    }
}
