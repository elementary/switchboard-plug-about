/*
* Copyright 2020–2021 elementary, Inc. (https://elementary.io)
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

public class About.OperatingSystemView : Gtk.Grid {
    private string support_url;

    private Gtk.Grid software_grid;

    construct {
        var style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("io/elementary/switchboard/system/OperatingSystemView.css");

        var uts_name = Posix.utsname ();

        support_url = Environment.get_os_info (GLib.OsInfoKey.SUPPORT_URL);
        if (support_url == "" || support_url == null) {
            support_url = "https://elementary.io/support";
        }

        var logo_icon_name = Environment.get_os_info ("LOGO");
        if (logo_icon_name == "" || logo_icon_name == null) {
            logo_icon_name = "distributor-logo";
        }

        var icon = new Gtk.Image () {
            icon_name = logo_icon_name,
        };

        var logo_overlay = new Gtk.Overlay ();

        if (Gtk.IconTheme.get_default ().has_icon (logo_icon_name + "-symbolic")) {
            foreach (unowned var path in Environment.get_system_data_dirs ()) {
                var file = File.new_for_path (
                    Path.build_path (Path.DIR_SEPARATOR_S, path, "backgrounds", "elementaryos-default")
                );

                if (file.query_exists ()) {
                    var file_icon = new FileIcon (file);

                    var logo = new Hdy.Avatar (128, "", false) {
                        loadable_icon = file_icon,
                        // We need this for the shadow to not get clipped by Gtk.Overlay
                        margin = 6
                    };
                    logo.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                    logo_overlay.add (logo);
                    logo_overlay.add_overlay (icon);

                    // 128 minus 3px padding on each side
                    icon.pixel_size = 128 - 6;

                    unowned var icon_style_context = icon.get_style_context ();
                    icon_style_context.add_class ("logo");
                    icon_style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                    break;
                }
            }
        }

        if (icon.parent == null) {
            icon.pixel_size = 128;
            logo_overlay.add (icon);
        }

        // Intentionally not using GLib.OsInfoKey.PRETTY_NAME here because we
        // want more granular control over text formatting
        var pretty_name = "<b>%s</b> %s".printf (
            Environment.get_os_info (GLib.OsInfoKey.NAME),
            Environment.get_os_info (GLib.OsInfoKey.VERSION) ?? ""
        );

        var title = new Gtk.Label (pretty_name) {
            ellipsize = Pango.EllipsizeMode.END,
            margin_bottom = 12,
            selectable = true,
            use_markup = true,
            xalign = 0
        };
        title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var kernel_version_label = new Gtk.Label ("%s %s".printf (uts_name.sysname, uts_name.release)) {
            selectable = true,
            xalign = 0
        };

        var website_url = Environment.get_os_info (GLib.OsInfoKey.HOME_URL);
        if (website_url == "" || website_url == null) {
            website_url = "https://elementary.io";
        }

        var website_label = new Gtk.LinkButton.with_label (website_url, _("Website")) {
            margin_top = 12
        };


        var help_button = new Gtk.LinkButton.with_label (support_url, _("Get Support")) {
            halign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 12
        };

        var translate_button = new Gtk.LinkButton.with_label (
            "https://l10n.elementary.io/projects/",
            _("Suggest Translations")
        ) {
            margin_top = 12
        };

        var bug_button = new Gtk.Button.with_label (_("Send Feedback"));

        Gtk.Button? update_button = null;
        var appcenter_info = new GLib.DesktopAppInfo ("io.elementary.appcenter.desktop");
        if (appcenter_info != null) {
            update_button = new Gtk.Button.with_label (_("Check for Updates"));
            update_button.clicked.connect (() => {
                appcenter_info.launch_action ("ShowUpdates", new GLib.AppLaunchContext ());
            });
        }

        var settings_restore_button = new Gtk.Button.with_label (_("Restore Default Settings"));

        var button_grid = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            hexpand = true,
            layout_style = Gtk.ButtonBoxStyle.END,
            spacing = 6
        };
        button_grid.add (settings_restore_button);
        button_grid.add (bug_button);
        if (update_button != null) {
            button_grid.add (update_button);
        }
        button_grid.set_child_secondary (settings_restore_button, true);

        software_grid = new Gtk.Grid () {
            // The avatar has some built-in margin for shadows
            column_spacing = 32 - 6,
            halign = Gtk.Align.CENTER,
            row_spacing = 6,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        software_grid.attach (logo_overlay, 0, 0, 1, 4);
        software_grid.attach (title, 1, 0, 3);

        software_grid.attach (kernel_version_label, 1, 2, 3);
        software_grid.attach (website_label, 1, 3);
        software_grid.attach (help_button, 2, 3);
        software_grid.attach (translate_button, 3, 3);

        margin = 12;
        orientation = Gtk.Orientation.VERTICAL;
        row_spacing = 12;
        add (software_grid);
        add (button_grid);
        show_all ();

        settings_restore_button.clicked.connect (settings_restore_clicked);

        bug_button.clicked.connect (() => {
            var appinfo = new GLib.DesktopAppInfo ("io.elementary.feedback.desktop");
            if (appinfo != null) {
                try {
                    appinfo.launch (null, null);
                } catch (Error e) {
                    critical (e.message);
                    launch_support_url ();
                }
            } else {
                launch_support_url ();
            }
        });

        get_upstream_release.begin ();
    }

    private async void get_upstream_release () {
        // Upstream distro version (for "Built on" text)
        // FIXME: Add distro specific field to /etc/os-release and use that instead
        // Like "ELEMENTARY_UPSTREAM_DISTRO_NAME" or something
        var file = File.new_for_path ("/usr/lib/upstream-os-release");
        string? upstream_release = null;
        try {
            var dis = new DataInputStream (yield file.read_async ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = yield dis.read_line_async ()) != null) {
                if (line.has_prefix ("PRETTY_NAME")) {
                    var distrib_component = line.split ("=", 2);
                    if (distrib_component.length == 2) {
                        upstream_release = (owned) distrib_component[1];
                        if (upstream_release.has_prefix ("\"") && upstream_release.has_suffix ("\"")) {
                            upstream_release = upstream_release.substring (1, upstream_release.length - 2);
                        }

                        break;
                    }
                }
            }
        } catch (Error e) {
            warning ("Couldn't read upstream lsb-release file, assuming none");
            debug ("Error was: %s", e.message);
        }

        if (upstream_release != null) {
            var based_off = new Gtk.Label (_("Built on %s").printf (upstream_release)) {
                selectable = true,
                xalign = 0
            };
            software_grid.attach (based_off, 1, 1, 3);
            software_grid.show_all ();
        }
    }

    private void launch_support_url () {
        try {
            AppInfo.launch_default_for_uri (support_url, null);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void settings_restore_clicked () {
        var dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("System Settings Will Be Restored to The Factory Defaults"),
            _("All system settings and data will be reset to the default values. Personal data, such as music and pictures, will be unaffected."),
            "dialog-warning",
            Gtk.ButtonsType.CANCEL
        );
        dialog.transient_for = (Gtk.Window) get_toplevel ();

        var continue_button = dialog.add_button (_("Restore Settings"), Gtk.ResponseType.ACCEPT);
        continue_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        dialog.response.connect ((response) => {
            dialog.destroy ();
            if (response == Gtk.ResponseType.ACCEPT) {
                var all_schemas = get_pantheon_schemas ();

                foreach (var schema in all_schemas) {
                    reset_recursively (schema);
                }
            }
        });
        dialog.present ();
    }

    private static void reset_all_keys (GLib.Settings settings) {
        var schema = SettingsSchemaSource.get_default ().lookup (
            settings.schema_id,
            true
        );

        foreach (var key in schema.list_keys ()) {
            settings.reset (key);
        }
    }

    private static string[] get_pantheon_schemas () {
        string[] schemas = {};
        string[] pantheon_schemas = {};
        string[] prefixes = {
            "org.pantheon.desktop",
            "io.elementary.desktop",
            "io.elementary.onboarding",
            "io.elementary.wingpanel.keyboard",
            "org.gnome.desktop",
            "org.gnome.settings-daemon"
        };

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

        foreach (var child in settings.list_children ()) {
            var child_settings = settings.get_child (child);

            reset_all_keys (child_settings);
        }
        settings.apply ();
        GLib.Settings.sync ();
    }
}
