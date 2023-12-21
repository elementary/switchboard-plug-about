/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2017–2023 elementary, Inc. (https://elementary.io)
 *                         2020 Justin Haygood <jhaygood86@gmail.com>
 *                         2010 Red Hat, Inc
 *                         2008 William Jon McCann <jmccann@redhat.com>
 */

public class About.HardwareView : Gtk.Box {
    private bool oem_enabled;
    private string manufacturer_icon_path;
    private string? manufacturer_icon_dark_path = null;
    private string manufacturer_name;
    private string manufacturer_support_url;
    private string memory;
    private string processor;
    private string product_name;
    private string product_version;
    private SystemInterface system_interface;
    private SessionManager? session_manager;
    private SwitcherooControl? switcheroo_interface;

    private Gtk.Image manufacturer_logo;

    private Gtk.Label primary_graphics_info;
    private Gtk.Label secondary_graphics_info;
    private Gtk.Box graphics_box;

    private Gtk.Label storage_info;

    private Granite.Settings granite_settings;

    construct {
        granite_settings = Granite.Settings.get_default ();

        fetch_hardware_info ();

        var product_name_info = new Gtk.Label (get_host_name ()) {
            ellipsize = MIDDLE,
            selectable = true,
            xalign = 0
        };
        product_name_info.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var processor_info = new Gtk.Label (processor) {
            ellipsize = MIDDLE,
            margin_top = 12,
            selectable = true,
            xalign = 0
        };

        var memory_info = new Gtk.Label (_("%s memory").printf (memory)) {
            ellipsize = MIDDLE,
            selectable = true,
            xalign = 0
        };

        primary_graphics_info = new Gtk.Label (_("Unknown Graphics")) {
            ellipsize = MIDDLE,
            selectable = true,
            xalign = 0
        };

        secondary_graphics_info = new Gtk.Label (null) {
            ellipsize = MIDDLE,
            selectable = true,
            xalign = 0
        };

        graphics_box = new Gtk.Box (VERTICAL, 6);
        graphics_box.append (primary_graphics_info);

        storage_info = new Gtk.Label (_("Unknown storage")) {
            ellipsize = MIDDLE,
            selectable = true,
            xalign = 0
        };

        var details_box = new Gtk.Box (VERTICAL, 6);

        manufacturer_logo = new Gtk.Image () {
            halign = END,
            pixel_size = 128,
            use_fallback = true
        };

        if (oem_enabled) {
            if (product_name != null) {
                product_name_info.label = "<b>%s</b>".printf (product_name);
                product_name_info.use_markup = true;
            }

            if (product_version != null) {
                 product_name_info.label += " %s".printf (product_version);
            }

            var manufacturer_info = new Gtk.Label (manufacturer_name) {
                ellipsize = MIDDLE,
                selectable = true,
                xalign = 0
            };
            manufacturer_info.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            details_box.append (product_name_info);
            details_box.append (manufacturer_info);
        } else {
            details_box.append (product_name_info);
        }

        update_manufacturer_logo ();

        details_box.append (processor_info);
        details_box.append (graphics_box);

        details_box.append (memory_info);
        details_box.append (storage_info);

        if (oem_enabled && manufacturer_support_url != null) {
            var manufacturer_website_info = new Gtk.LinkButton.with_label (
                manufacturer_support_url,
                _("Manufacturer Website")
            ) {
                halign = START,
                margin_top = 12
                // xalign = 0
            };

            details_box.append (manufacturer_website_info);
        }

        margin_start = 16;
        margin_end = 16;
        spacing = 32;
        halign = CENTER;

        append (manufacturer_logo);
        append (details_box);

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            update_manufacturer_logo ();
        });
    }

    private void update_manufacturer_logo () {
        if (oem_enabled) {
            string path = manufacturer_icon_path;
            if (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK && manufacturer_icon_dark_path != null) {
                path = manufacturer_icon_dark_path;
            }
            var fileicon = new FileIcon (File.new_for_path (path));

            if (path != null) {
                manufacturer_logo.gicon = fileicon;
            }
        }

        if (manufacturer_logo.gicon == null) {
            load_fallback_manufacturer_icon.begin ();
        }
    }

    private async void load_fallback_manufacturer_icon () {
        get_system_interface_instance ();

        if (system_interface != null) {
            manufacturer_logo.icon_name = system_interface.icon_name;
        }
    }

    private string? try_get_arm_model (GLib.HashTable<string, string> values) {
        string? cpu_implementer = values.lookup ("CPU implementer");
        string? cpu_part = values.lookup ("CPU part");

        if (cpu_implementer == null || cpu_part == null) {
            return null;
        }

        return ARMPartDecoder.decode_arm_model (cpu_implementer, cpu_part);
    }

    private string? get_cpu_info () {
        unowned GLibTop.sysinfo? info = GLibTop.get_sysinfo ();

        if (info == null) {
            return null;
        }

        var counts = new Gee.HashMap<string, uint> ();
        const string[] KEYS = { "model name", "cpu", "Processor" };

        for (int i = 0; i < info.ncpu; i++) {
            unowned GLib.HashTable<string, string> values = info.cpuinfo[i].values;
            string? model = null;
            foreach (var key in KEYS) {
                model = values.lookup (key);

                if (model != null) {
                    break;
                }
            }

            if (model == null) {
                model = try_get_arm_model (values);
                if (model == null) {
                    continue;
                }
            }

            string? core_count = values.lookup ("cpu cores");
            if (core_count != null) {
                counts.@set (model, uint.parse (core_count));
                continue;
            }

            if (!counts.has_key (model)) {
                counts.@set (model, 1);
            } else {
                counts.@set (model, counts.@get (model) + 1);
            }
        }

        if (counts.size == 0) {
            return null;
        }

        string result = "";
        foreach (var cpu in counts.entries) {
            if (result.length > 0) {
                result += "\n";
            }

            if (cpu.@value == 2) {
                result += _("Dual-Core %s").printf (clean_name (cpu.key));
            } else if (cpu.@value == 4) {
                result += _("Quad-Core %s").printf (clean_name (cpu.key));
            } else if (cpu.@value == 6) {
                result += _("Hexa-Core %s").printf (clean_name (cpu.key));
            } else {
                result += "%u \u00D7 %s ".printf (cpu.@value, clean_name (cpu.key));
            }
        }

        return result;
    }

    private async string? get_gpu_info (bool primary) {
        if (session_manager == null) {
            try {
                session_manager = yield Bus.get_proxy (
                    BusType.SESSION,
                    "org.gnome.SessionManager",
                    "/org/gnome/SessionManager"
                );
            } catch (IOError e) {
                warning ("Unable to connect to GNOME Session Manager for GPU details: %s", e.message);
            }
        }

        if (switcheroo_interface == null) {
            try {
                switcheroo_interface = yield Bus.get_proxy (
                    BusType.SYSTEM,
                    "net.hadess.SwitcherooControl",
                    "/net/hadess/SwitcherooControl"
                );
            } catch (Error e) {
                warning ("Unable to connect to switcheroo-control: %s", e.message);
            }
        }

        string? gpu_name = null;

        const string[] FALLBACKS = {
            "Intel Corporation"
        };

        if (switcheroo_interface != null) {
            if (!primary && !switcheroo_interface.has_dual_gpu) {
                return null;
            }

            foreach (unowned HashTable<string,Variant> gpu in switcheroo_interface.gpus) {
                bool is_default = gpu.get ("Default").get_boolean ();

                if (is_default == primary) {
                    unowned string candidate = gpu.get ("Name").get_string ();
                    if (candidate in FALLBACKS) {
                        continue;
                    }
                    gpu_name = clean_name (candidate);
                }
            }
        }

        if (gpu_name != null) {
            return gpu_name;
        }

        // Switcheroo failed to get the name of the secondary GPU, we'll assume there isn't one
        // and return null
        if (!primary) {
            return null;
        }

        if (session_manager != null) {
            return clean_name (session_manager.renderer);
        }

        return _("Unknown Graphics");
    }

    private async void get_graphics_info () {
        var primary_gpu = yield get_gpu_info (true);
        primary_graphics_info.label = primary_gpu;

        var secondary_gpu = yield get_gpu_info (false);
        if (secondary_gpu != null) {
            secondary_graphics_info.label = secondary_gpu;
            graphics_box.append (secondary_graphics_info);
        }
    }

    private string get_mem_info () {
        uint64 mem_total = 0;

        GUdev.Client client = new GUdev.Client ({"dmi"});
        GUdev.Device? device = client.query_by_sysfs_path ("/sys/devices/virtual/dmi/id");

        if (device != null) {
            uint64 devices = device.get_property_as_uint64 ("MEMORY_ARRAY_NUM_DEVICES");
            for (int item = 0; item < devices; item++) {
                mem_total += device.get_property_as_uint64 ("MEMORY_DEVICE_%d_SIZE".printf (item));
            }
        }

        if (mem_total == 0) {
            GLibTop.mem mem;
            GLibTop.get_mem (out mem);
            mem_total = mem.total;
        }

        return custom_format_size (mem_total, true);
    }

    private void fetch_hardware_info () {
        string? cpu = get_cpu_info ();

        if (cpu == null) {
            processor = _("Unknown Processor");
        } else {
            processor = cpu;
        }

        memory = get_mem_info ();

        get_graphics_info.begin ();
        get_storage_info.begin ();

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

            if (oem_file.has_key ("OEM", "LogoDark")) {
                manufacturer_icon_dark_path = oem_file.get_string ("OEM", "LogoDark");
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

    private async void get_storage_info () {
        var file_root = GLib.File.new_for_path ("/");
        string storage_capacity = "";

        uint64 storage_total = 0;

        try {
            UDisks.Client client = yield new UDisks.Client (null);
            foreach (unowned var object in client.object_manager.get_objects ()) {
                UDisks.Drive drive = ((UDisks.Object)object).drive;
                if (drive == null || drive.removable || drive.ejectable) {
                    continue;
                }
                storage_total += drive.size;
            }
            if (storage_total != 0) {
                storage_capacity = custom_format_size (storage_total, false);
                storage_info.label = yield get_storage_type (storage_capacity);
                return;
            }
        } catch (Error e) {
            warning (e.message);
        }

        try {
            var info = yield file_root.query_filesystem_info_async (GLib.FileAttribute.FILESYSTEM_SIZE);
            storage_capacity = custom_format_size (info.get_attribute_uint64 (GLib.FileAttribute.FILESYSTEM_SIZE), false);
        } catch (Error e) {
            critical (e.message);
            storage_capacity = _("Unknown");
        }

        storage_info.label = yield get_storage_type (storage_capacity);
    }

    private string clean_name (string info) {

        string pretty = GLib.Markup.escape_text (info).strip ();

        const ReplaceStrings REPLACE_STRINGS[] = {
            { "Mesa DRI ", ""},
            { "Mesa (.*)", "\\1"},
            { "[(]R[)]", "®"},
            { "[(]TM[)]", "™"},
            { "Gallium .* on (AMD .*)", "\\1"},
            { "(AMD .*) [(].*", "\\1"},
            { "(AMD Ryzen) (.*)", "\\1 \\2"},
            { "(AMD [A-Z])(.*)", "\\1\\L\\2\\E"},
            { "Advanced Micro Devices, Inc\\. \\[.*?\\] .*? \\[(.*?)\\] .*", "AMD® \\1"},
            { "Advanced Micro Devices, Inc\\. \\[.*?\\] (.*)", "AMD® \\1"},
            { "Graphics Controller", "Graphics"},
            { "Intel Corporation", "Intel®"},
            { "NVIDIA Corporation (.*) \\[(\\S*) (\\S*) (.*)\\]", "NVIDIA® \\2® \\3® \\4"}
        };

        try {
            foreach (ReplaceStrings replace_string in REPLACE_STRINGS) {
                GLib.Regex re = new GLib.Regex (replace_string.regex, 0, 0);
                bool matched = re.match (pretty);
                pretty = re.replace (pretty, -1, 0, replace_string.replacement, 0);
                if (matched) {
                    break;
                }
            }
        } catch (Error e) {
            critical ("Couldn't cleanup vendor string: %s", e.message);
        }

        return pretty;
    }

    private async string get_storage_type (string storage_capacity) {
        string partition_name = yield get_partition_name ();
        string disk_name = yield get_disk_name (partition_name);
        string path = "/sys/block/%s/queue/rotational".printf (disk_name);
        string storage = "";
        try {
            var file = File.new_for_path (path);
            var dis = new DataInputStream (yield file.read_async ());
            // Only a single line in this "file"
            string contents = yield dis.read_line_async ();

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
        } catch (Error e) {
            warning (e.message);
            // Set fallback string for the device type
            storage = _("%s storage").printf (storage_capacity);
        }
        return storage;
    }

    private async string get_partition_name () {
        string df_stdout;
        string partition = "";
        try {
            var subprocess = new GLib.Subprocess (GLib.SubprocessFlags.STDOUT_PIPE, "df", "/");
            yield subprocess.communicate_utf8_async (null, null, out df_stdout, null);
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

    private async string get_disk_name (string partition) {
        string lsblk_stout;
        string disk_name = "";
        try {
            var subprocess = new GLib.Subprocess (GLib.SubprocessFlags.STDOUT_PIPE, "lsblk", "-no", "pkname", partition);
            yield subprocess.communicate_utf8_async (null, null, out lsblk_stout, null);
            disk_name = lsblk_stout.strip ();
        } catch (Error e) {
            warning (e.message);
        }
        return disk_name;
    }

    struct ReplaceStrings {
        string regex;
        string replacement;
    }

    private void get_system_interface_instance () {
        if (system_interface == null) {
            try {
                system_interface = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "org.freedesktop.hostname1",
                    "/org/freedesktop/hostname1"
                );
            } catch (GLib.Error e) {
                warning ("%s", e.message);
            }
        }
    }

    private string get_host_name () {
        get_system_interface_instance ();

        if (system_interface == null) {
            return GLib.Environment.get_host_name ();
        }

        string hostname = system_interface.pretty_hostname;

        if (hostname.length == 0) {
            hostname = system_interface.static_hostname;
        }

        return hostname;
    }

    // Format layperson-friendly size string, replacement for GLib.format_size ().
    // Always return "GB", "TB" etc. even if IEC_UNITS requested, instead
    // of "GiB", "TiB" etc. for the benefit of average users.
    private string custom_format_size (uint64 size, bool iec_unit) {
        uint divisor = iec_unit ? 1024 : 1000;

#if HAS_GLIB_2_73
        const string[] UNITS = {"kB", "MB", "GB", "TB", "PB", "EB"};
#else
        const string[] UNITS = {"%.1f kB", "%.1f MB", "%.1f GB", "%.1f TB", "%.1f PB", "%.1f EB"};
#endif

        int unit_index = 0;

        while ((size / divisor) > 0 && (unit_index < UNITS.length)) {
            unit_index++;
            size /= divisor;
        }

        unowned string unit;

        if (unit_index == 0) {
#if HAS_GLIB_2_73
            unit = dngettext ("glib20", "byte", "bytes", (ulong) size);
#else
            return dngettext ("glib20", "%u byte", "%u bytes", (ulong) size).printf ((uint) size);
#endif
        } else {
            unit = dgettext ("glib20", UNITS[unit_index - 1]);
        }

#if HAS_GLIB_2_73
        return dpgettext2 ("glib20", "format-size", "%u %s").printf ((uint) size, unit);
#else
        return unit.printf ((float) size);
#endif
    }
}

[DBus (name = "org.freedesktop.hostname1")]
public interface SystemInterface : Object {
    [DBus (name = "IconName")]
    public abstract string icon_name { owned get; }

    public abstract string pretty_hostname { owned get; }
    public abstract string static_hostname { owned get; }
}

[DBus (name = "org.gnome.SessionManager")]
public interface SessionManager : Object {
    [DBus (name = "Renderer")]
    public abstract string renderer { owned get;}
}

[DBus (name = "net.hadess.SwitcherooControl")]
public interface SwitcherooControl : Object {
    [DBus (name = "HasDualGpu")]
    public abstract bool has_dual_gpu { owned get; }

    [DBus (name = "GPUs")]
    public abstract HashTable<string,Variant>[] gpus { owned get; }
}
