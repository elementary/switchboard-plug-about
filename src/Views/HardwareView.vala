/*
* Copyright (C) 2010 Red Hat, Inc
* Copyright (C) 2008 William Jon McCann <jmccann@redhat.com>
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
* Copyright (C) 2020 Justin Haygood <jhaygood86@gmail.com>
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

public class About.HardwareView: Gtk.Grid {
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
    private SystemInterface system_interface;
    private SessionManager session_manager;

    construct {
        try {
            session_manager = Bus.get_proxy_sync (BusType.SESSION,
                "org.gnome.SessionManager", "/org/gnome/SessionManager");
        } catch (IOError e) {
            critical (e.message);
            graphics = _("Unknown Graphics");
        }

        fetch_hardware_info ();

        try {
            system_interface = Bus.get_proxy_sync (BusType.SYSTEM,
                "org.freedesktop.hostname1", "/org/freedesktop/hostname1");
        } catch (IOError e) {
            critical (e.message);
        }

        var manufacturer_logo = new Gtk.Image ();
        manufacturer_logo.icon_name = system_interface.icon_name;
        manufacturer_logo.hexpand = true;
        manufacturer_logo.pixel_size = 128;
        manufacturer_logo.use_fallback = true;

        var product_name_info = new Gtk.Label (product_name);
        product_name_info.ellipsize = Pango.EllipsizeMode.END;
        product_name_info.get_style_context ().add_class ("h2");
        product_name_info.set_selectable(true);

        var hostname_label = new Gtk.Label (_("Hostname:"));
        hostname_label.halign = Gtk.Align.END;

        var hostname_info = new Gtk.Entry ();
        hostname_info.set_text(Environment.get_host_name ());
        hostname_info.valign = Gtk.Align.CENTER;
        hostname_info.activate.connect (() => {
            string hostname = hostname_info.get_text ();
            var cleaned_hostname = clean_hostname (hostname);
            change_hostname (cleaned_hostname);
            hostname_info.set_text(cleaned_hostname);
        });

        var processor_info = new Gtk.Label (processor);
        processor_info.ellipsize = Pango.EllipsizeMode.END;
        processor_info.margin_top = 12;
        processor_info.set_selectable (true);

        var memory_info = new Gtk.Label (_("%s memory").printf (memory));
        memory_info.ellipsize = Pango.EllipsizeMode.END;
        memory_info.set_selectable (true);

        var graphics_info = new Gtk.Label (graphics);
        graphics_info.ellipsize = Pango.EllipsizeMode.END;
        graphics_info.justify = Gtk.Justification.CENTER;
        graphics_info.set_selectable (true);

        var hdd_info = new Gtk.Label(hdd);
        hdd_info.ellipsize = Pango.EllipsizeMode.END;
        hdd_info.set_selectable (true);

        column_spacing = 6;
        row_spacing = 6;
        attach (manufacturer_logo, 0, 0, 2, 1);
        attach (hostname_info, 1, 4, 1, 1);
        attach (hostname_label, 0, 4);
        attach (processor_info, 0, 5, 2, 1);
        attach (graphics_info, 0, 6, 2, 1);
        attach (memory_info, 0, 7, 2, 1);
        attach (hdd_info, 0, 8, 2, 1);

        if (oem_enabled) {
            var fileicon = new FileIcon(File.new_for_path (manufacturer_icon_path));

            if (manufacturer_icon_path != null) {
                manufacturer_logo.icon_name = null;
                manufacturer_logo.gicon = fileicon;
            }

            var manufacturer_info = new Gtk.Label (manufacturer_name);
            manufacturer_info.ellipsize = Pango.EllipsizeMode.END;
            manufacturer_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            manufacturer_info.set_selectable (true);

            attach (manufacturer_info, 0, 2, 2, 1);

            if (product_name != null) {

                if (product_version != null) {
                    var product_version_info = new Gtk.Label ("(" + product_version + ")");
                    product_version_info.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
                    product_version_info.set_selectable (true);
                    product_version_info.ellipsize = Pango.EllipsizeMode.END;
                    product_version_info.xalign = 0;
                    product_name_info.xalign = 1;
                    attach (product_name_info, 0, 1, 1, 1);
                    attach (product_version_info, 1, 1, 1, 1);
                } else {
                    attach (product_name_info, 0, 1, 2, 1);
                }
            }

            if (manufacturer_support_url != null) {
                var manufacturer_website_info = new Gtk.LinkButton.with_label (manufacturer_support_url, _("Manufacturer Website"));
                attach (manufacturer_website_info, 0, 9, 2, 1);
            }
        } else {
            attach (product_name_info, 0, 1, 2, 1);
        }
    }

    private string clean_hostname(string hostname) {
        string cleaned_hostname = hostname.replace (" ", "-");
        return cleaned_hostname;
    }

    private void change_hostname(string hostname) {
        if (hostname.length == 0) {
            hostname = "localhost";
        }

        try {
            Process.spawn_command_line_async ("hostnamectl set-hostname %s".printf(hostname.to_ascii ()));
        } catch (SpawnError e) {
            warning (e.message);
        }

    }

    private void fetch_hardware_info() {
        // Processor
        var cpu_file = File.new_for_path ("/proc/cpuinfo");
        uint cores = 0;
        bool cores_found = false;
        try {
            var dis = new DataInputStream (cpu_file.read());
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
            processor = _("Unknown Processor");
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

        // Memory
        memory = GLib.format_size ( get_mem_info ());

        // Graphics
        try {
            Process.spawn_command_line_sync ("lspci", out graphics);

            if ("VGA" in graphics) { //VGA-keyword indicates graphics-line
                string[] lines = graphics.split ("\n");
                graphics = "";

                foreach(var s in lines) {
                    if ("VGA" in s || "3D" in s) {
                        string model = get_graphics_from_string (s);

                        if (graphics == "") {
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

        graphics = clean_graphics_name (session_manager.renderer);

        // Hard Drive
        var file_root = GLib.File.new_for_path ("/");
        string storage_capacity = "";
        try {
            var info = file_root.query_filesystem_info(GLib.FileAttribute.FILESYSTEM_SIZE, null);
            storage_capacity = GLib.format_size(info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_SIZE));
        } catch (Error e) {
            critical (e.message);
            storage_capacity = _("Unknown");
        }

        hdd = get_storage_type (storage_capacity);

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

    private string clean_graphics_name (string info) {

        string pretty = GLib.Markup.escape_text (info).strip ();

        const GraphicsReplaceStrings REPLACE_STRINGS[] = {
            { "Mesa DRI ", ""},
            { "[(]R[)]", "®"},
            { "[(]TM[)]", "™"},
            { "Gallium .* on (AMD .*)", "\\1"},
            { "(AMD .*) [(].*", "\\1"},
            { "(AMD [A-Z])(.*)", "\\1\\L\\2\\E"},
            { "Graphics Controller", "Graphics"},
        };

        try {
            foreach (GraphicsReplaceStrings replace_string in REPLACE_STRINGS) {
                GLib.Regex re = new GLib.Regex (replace_string.regex, 0, 0);
                pretty = re.replace (pretty, -1, 0, replace_string.replacement, 0);
            }
        } catch (Error e) {
            critical ("Couldn't pretty graphics string: %s", e.message);
        }

        return pretty;
    }

    private uint64 get_mem_info () {
        File file = File.new_for_path ("/proc/meminfo");
        try {
            DataInputStream dis = new DataInputStream (file.read ());
            string? line;
            string name = "MemTotal:";
            while ((line = dis.read_line (null, null)) != null) {
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

    private string get_storage_type (string storage_capacity) {
        string partition_name = get_partition_name ();
        string disk_name = get_disk_name (partition_name);
        string path = "/sys/block/%s/queue/rotational".printf (disk_name);
        string storage = "";
        try {
            string contents;
            FileUtils.get_contents (path, out contents);
            if (int.parse (contents) == 0) {
                if (disk_name.has_prefix ("nvme")) {
                    storage = _("%s storage (NVMe SSD)").printf (storage_capacity);
                } else if (disk_name.has_prefix ("mmc")) {
                    storage = _("%s storage (eMMC)").printf (storage_capacity);
                } else {
                    storage = _("%s storage (SATA SSD)").printf (storage_capacity);
                }
            } else {
                storage = _("%s storage (HDD)").printf (storage_capacity);
            }
        } catch (FileError e) {
            warning (e.message);
            // Set fallback string for the device type
            storage = _("%s storage").printf (storage_capacity);
        }
        return storage;
    }

    private string get_partition_name () {
        string df_stdout;
        string partition = "";
        try {
            Process.spawn_command_line_sync ("df /",
                out df_stdout);
            string[] output = df_stdout.split ("\n");
            foreach (string line in output) {
                if (line.has_prefix ("/dev/")) {
                    int idx = line.index_of (" ");
                    if (idx != -1) {
                        partition = line.substring (0, idx);
                        return partition;
                    }
                }
            }
        } catch (Error e) {
            warning (e.message);
        }
        return partition;
    }

    private string get_disk_name (string partition) {
        string lsblk_stout;
        string disk_name = "";
        string command = "lsblk -no pkname " + partition;
        try {
            Process.spawn_command_line_sync (command,
                out lsblk_stout);
            disk_name = lsblk_stout.strip ();
        } catch (Error e) {
            warning (e.message);
        }
        return disk_name;
    }

    struct GraphicsReplaceStrings {
        string regex;
        string replacement;
    }
}

[DBus (name = "org.freedesktop.hostname1")]
public interface SystemInterface : Object {
    [DBus (name = "IconName")]
    public abstract string icon_name { owned get; }
}

[DBus (name = "org.gnome.SessionManager")]
public interface SessionManager : Object {
    [DBus (name = "Renderer")]
    public abstract string renderer { owned get;}
}
