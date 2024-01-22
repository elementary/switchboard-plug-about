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

public class About.OperatingSystemView : Gtk.Box {
    private string support_url;

    private Gtk.StringList updates;
    private SystemUpdate? update_proxy = null;
    private Gtk.Grid software_grid;
    private Gtk.Button check_button;
    private Gtk.Image updates_image;
    private Gtk.Label updates_title;
    private Gtk.Label updates_description;
    private Gtk.Revealer update_button_revealer;
    private Gtk.Revealer cancel_button_revealer;
    private Gtk.Revealer error_button_revealer;

    construct {
        var style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("io/elementary/settings/system/OperatingSystemView.css");

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

        if (Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).has_icon (logo_icon_name + "-symbolic")) {
            foreach (unowned var path in Environment.get_system_data_dirs ()) {
                var file = File.new_for_path (
                    Path.build_path (Path.DIR_SEPARATOR_S, path, "backgrounds", "elementaryos-default")
                );

                if (file.query_exists ()) {
                    var logo = new Adw.Avatar (128, "", false) {
                        custom_image = Gdk.Texture.from_file (file)
                    };
                    logo.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                    logo_overlay.child = logo;
                    logo_overlay.add_overlay (icon);

                    // 128 minus 3px padding on each side
                    icon.pixel_size = 128 - 6;
                    icon.add_css_class ("logo");
                    icon.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                    break;
                }
            }
        }

        if (icon.parent == null) {
            icon.pixel_size = 128;
            logo_overlay.child = icon;
        }

        // Intentionally not using GLib.OsInfoKey.PRETTY_NAME here because we
        // want more granular control over text formatting
        var pretty_name = "<b>%s</b> %s".printf (
            Environment.get_os_info (GLib.OsInfoKey.NAME),
            Environment.get_os_info (GLib.OsInfoKey.VERSION) ?? ""
        );

        var title = new Gtk.Label (pretty_name) {
            ellipsize = Pango.EllipsizeMode.END,
            selectable = true,
            use_markup = true,
            xalign = 0
        };
        title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var kernel_version_label = new Gtk.Label ("%s %s".printf (uts_name.sysname, uts_name.release)) {
            selectable = true,
            xalign = 0
        };
        kernel_version_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        kernel_version_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var website_url = Environment.get_os_info (GLib.OsInfoKey.HOME_URL);
        if (website_url == "" || website_url == null) {
            website_url = "https://elementary.io";
        }

        var website_label = new Gtk.LinkButton.with_label (website_url, _("Website"));


        var help_button = new Gtk.LinkButton.with_label (support_url, _("Get Support")) {
            halign = Gtk.Align.CENTER,
            hexpand = true
        };

        var translate_button = new Gtk.LinkButton.with_label (
            "https://l10n.elementary.io/projects/",
            _("Suggest Translations")
        );

        var bug_button = new Gtk.Button.with_label (_("Send Feedback"));

        updates = new Gtk.StringList (null);

        var update_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        update_list.bind_model (updates, (obj) => {
            var str = ((Gtk.StringObject) obj).string;
            return new Gtk.Label (str);
        });

        var update_scrolled = new Gtk.ScrolledWindow () {
            child = update_list
        };

        updates_image = new Gtk.Image () {
            icon_size = LARGE,
            margin_end = 6
        };

        updates_title = new Gtk.Label (null) {
            hexpand = true,
            margin_end = 6,
            xalign = 0
        };

        updates_description = new Gtk.Label (null) {
            xalign = 0
        };
        updates_description.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        updates_description.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var update_button = new Gtk.Button.with_label (_("Download")) {
            margin_end = 6,
            valign = CENTER
        };
        update_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        update_button_revealer = new Gtk.Revealer () {
            child = update_button,
            overflow = VISIBLE,
            transition_type = SLIDE_LEFT
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            margin_end = 6,
            valign = CENTER
        };

        cancel_button_revealer = new Gtk.Revealer () {
            child = cancel_button,
            overflow = VISIBLE,
            transition_type = SLIDE_LEFT
        };

        var error_button = new Gtk.Button.with_label (_("Refresh")) {
            margin_end = 6,
            valign = CENTER
        };

        error_button_revealer = new Gtk.Revealer () {
            child = error_button,
            overflow = VISIBLE,
            transition_type = SLIDE_LEFT
        };

        var updates_grid = new Gtk.Grid () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        updates_grid.attach (updates_image, 0, 0, 1, 2);
        updates_grid.attach (updates_title, 1, 0);
        updates_grid.attach (updates_description, 1, 1);
        updates_grid.attach (update_button_revealer, 2, 0, 1, 2);
        updates_grid.attach (cancel_button_revealer, 3, 0, 1, 2);
        updates_grid.attach (error_button_revealer, 4, 0, 1, 2);

        var frame = new Gtk.Frame (null) {
            child = updates_grid,
            margin_bottom = 12,
            margin_top = 12,
            valign = CENTER
        };
        frame.add_css_class (Granite.STYLE_CLASS_VIEW);

        check_button = new Gtk.Button.with_label (_("Check for Updates"));

        var settings_restore_button = new Gtk.Button.with_label (_("Restore Default Settings"));

        var primary_button_box = new Gtk.Box (HORIZONTAL, 6) {
            hexpand = true,
            halign = END,
            homogeneous = true
        };
        primary_button_box.append (bug_button);
        primary_button_box.append (check_button);

        var button_grid = new Gtk.Box (HORIZONTAL, 6);
        button_grid.append (settings_restore_button);
        button_grid.append (primary_button_box);

        software_grid = new Gtk.Grid () {
            column_spacing = 32,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        software_grid.attach (logo_overlay, 0, 0, 1, 4);
        software_grid.attach (title, 1, 0, 3);

        software_grid.attach (kernel_version_label, 1, 2, 3);
        software_grid.attach (frame, 1, 3, 3);
        software_grid.attach (website_label, 1, 4);
        software_grid.attach (help_button, 2, 4);
        software_grid.attach (translate_button, 3, 4);

        margin_top = 12;
        margin_end = 12;
        margin_bottom = 12;
        margin_start = 12;
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;
        append (software_grid);
        append (button_grid);

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

        Bus.get_proxy.begin<SystemUpdate> (SESSION, "io.elementary.settings-daemon", "/io/elementary/settings_daemon", 0, null, (obj, res) => {
            try {
                update_proxy = Bus.get_proxy.end (res);

                update_proxy.state_changed.connect (update_state);
                update_state.begin ();
            } catch (Error e) {
                critical ("Failed to get updates proxy");
            }
        });

        check_button.clicked.connect (() => {
            if (update_proxy != null) {
                update_proxy.check_for_updates.begin (false, (obj, res) => {
                    try {
                        update_proxy.check_for_updates.end (res);
                    } catch (Error e) {
                        critical ("Failed to check for updates: %s", e.message);
                    }
                });
            }
        });

        update_button.clicked.connect (() => {
            if (update_proxy != null) {
                update_proxy.update.begin ((obj, res) => {
                    try {
                        update_proxy.update.end (res);
                    } catch (Error e) {
                        critical ("Failed to update: %s", e.message);
                    }
                });
            }
        });

        cancel_button.clicked.connect (() => {
            if (update_proxy != null) {
                update_proxy.cancel.begin ((obj, res) => {
                    try {
                        update_proxy.cancel.end (res);
                    } catch (Error e) {
                        critical ("Failed to cancel update: %s", e.message);
                    }
                });
            }
        });

        error_button.clicked.connect (() => {
            if (update_proxy != null) {
                update_proxy.check_for_updates.begin (true, (obj, res) => {
                    try {
                        update_proxy.check_for_updates.end (res);
                    } catch (Error e) {
                        critical ("Failed to force refresh: %s", e.message);
                    }
                });
            }
        });
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
            based_off.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
            based_off.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
            software_grid.attach (based_off, 1, 1, 3);
        }
    }

    private async void update_state () {
        if (update_proxy == null) {
            return;
        }

        SystemUpdate.CurrentState current_state;
        try {
            current_state = yield update_proxy.get_current_state ();
        } catch (Error e) {
            critical ("Failed to get current state from Updates Backend: %s", e.message);
            return;
        }

        update_button_revealer.reveal_child = current_state.state == AVAILABLE;
        cancel_button_revealer.reveal_child = current_state.state == DOWNLOADING;
        error_button_revealer.reveal_child = current_state.state == ERROR;

        switch (current_state.state) {
            case UP_TO_DATE:
                updates_image.icon_name = "process-completed";
                updates_title.label = _("Up To Date");
                updates_description.label = _("No updates available");
                check_button.sensitive = true;
                break;
            case CHECKING:
                updates_image.icon_name = "emblem-synchronized";
                updates_title.label = _("Checking for Updates");
                updates_description.label = current_state.message;
                check_button.sensitive = false;
                break;
            case AVAILABLE:
                updates_image.icon_name = "software-update-available";
                updates_title.label = _("Updates Available");
                check_button.sensitive = true;

                try {
                    var details = yield update_proxy.get_update_details ();
                    updates_description.label = ngettext (
                        _("%i update available").printf (details.packages.length),
                        _("%i updates available").printf (details.packages.length),
                        details.packages.length
                    );

                    updates.splice (0, 0, details.packages);
                } catch (Error e) {
                    updates_description.label = _("Unable to determine number of updates");
                    warning ("Failed to get updates list from backend: %s", e.message);
                }
                break;
            case DOWNLOADING:
                updates_image.icon_name = "browser-download";
                updates_title.label = _("Downloading Updates");
                updates_description.label = current_state.message;
                check_button.sensitive = false;
                break;
            case RESTART_REQUIRED:
                updates_image.icon_name = "system-reboot";
                updates_title.label = _("Restart Required");
                updates_description.label = _("A restart is required to finish installing updates");
                check_button.sensitive = false;
                break;
            case ERROR:
                updates_image.icon_name = "dialog-error";
                updates_title.label = _("Failed to download updates");
                updates_description.label = _("Manually refreshing updates may resolve the issue.");
                check_button.sensitive = false;
                break;
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
        dialog.transient_for = (Gtk.Window) get_root ();

        var continue_button = dialog.add_button (_("Restore Settings"), Gtk.ResponseType.ACCEPT);
        continue_button.get_style_context ().add_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

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
