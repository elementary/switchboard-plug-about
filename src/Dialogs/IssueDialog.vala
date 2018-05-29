/*
* Copyright (c) 2018 elementary LLC. (https://elementary.io)
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

public class About.IssueDialog : Granite.MessageDialog {
    private Gtk.ListBox listbox;
    private Category? category_filter;

    public IssueDialog () {
        Object (
            image_icon: new ThemedIcon ("dialog-question"), 
            primary_text: _("Which of the Following Are You Seeing an Issue With?"),
            secondary_text: _("Please select a component from the list."),
            resizable: true,
            modal: true
        );
    }

    construct {
        var apps_category = new CategoryRow (Category.DEFAULT_APPS);
        var panel_category = new CategoryRow (Category.PANEL);
        var settings_category = new CategoryRow (Category.SETTINGS);
        var system_category = new CategoryRow (Category.SYSTEM);

        var category_list = new Gtk.ListBox ();
        category_list.activate_on_single_click = true;
        category_list.selection_mode = Gtk.SelectionMode.NONE;
        category_list.add (apps_category);
        category_list.add (panel_category);
        category_list.add (settings_category);
        category_list.add (system_category);

        var back_button = new Gtk.Button.with_label (_("Categories"));
        back_button.halign = Gtk.Align.START;
        back_button.margin = 6;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var category_title = new Gtk.Label ("");

        var category_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        category_header.pack_start (back_button);
        category_header.set_center_widget (category_title);

        listbox = new Gtk.ListBox ();
        listbox.expand = true;
        listbox.set_filter_func (filter_function);
        listbox.set_sort_func (sort_function);

        foreach (var app in app_entries) {
            var desktop_info = new DesktopAppInfo (app.app_id + ".desktop");
            var repo_row = new RepoRow (desktop_info.get_display_name (), desktop_info.get_icon (), Category.DEFAULT_APPS, app.github_suffix);
            listbox.add (repo_row);
        }

        foreach (var entry in system_entries) {
            var repo_row = new RepoRow (entry.name, null, Category.SYSTEM, entry.github_suffix);
            listbox.add (repo_row);
        }

        foreach (var entry in switchboard_entries) {
            var repo_row = new RepoRow (dgettext (entry.gettext_domain, entry.name), new ThemedIcon (entry.icon), Category.SETTINGS, entry.github_suffix);
            listbox.add (repo_row);
        }

        foreach (var entry in wingpanel_entries) {
            var repo_row = new RepoRow (dgettext (entry.gettext_domain, entry.name), new ThemedIcon (entry.icon), Category.PANEL, entry.github_suffix);
            listbox.add (repo_row);
        }

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (listbox);

        var repo_list_grid = new Gtk.Grid ();
        repo_list_grid.orientation = Gtk.Orientation.VERTICAL;
        repo_list_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        repo_list_grid.add (category_header);
        repo_list_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        repo_list_grid.add (scrolled);

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add (category_list);
        stack.add (repo_list_grid);

        var frame = new Gtk.Frame (null);
        frame.add (stack);

        custom_bin.add (frame);
        custom_bin.show_all ();

        height_request = 500;

        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var report_button = add_button (_("Report Problem"), 0);
        report_button.sensitive = false;
        report_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        category_list.row_activated.connect ((row) => {
            stack.visible_child = repo_list_grid;
            category_filter = ((CategoryRow) row).category;
            category_title.label = ((CategoryRow) row).category.to_string ();
            listbox.invalidate_filter ();
            var adjustment = scrolled.get_vadjustment ();
            adjustment.set_value (adjustment.lower);
        });

        back_button.clicked.connect (() => {
            stack.visible_child = category_list;
            report_button.sensitive = false;
        });

        listbox.selected_rows_changed.connect (() => {
            foreach (var repo_row in listbox.get_children ()) {
                ((RepoRow) repo_row).selected = false;
            }
            ((RepoRow) listbox.get_selected_row ()).selected = true;
            report_button.sensitive = true;
        });

        response.connect (on_response);
    }

    private void on_response (Gtk.Dialog source, int response_id) {
        if (response_id == 0) {
            try {
                var url = ((RepoRow) listbox.get_selected_row ()).url;
                AppInfo.launch_default_for_uri ("https://github.com/elementary/%s/issues".printf (url), null);
            } catch (Error e) {
                critical (e.message);
            }
        }

        destroy ();
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (Gtk.ListBoxRow row) {
        if (((RepoRow) row).category == category_filter) {
            return true;
        }
        return false;
    }

    [CCode (instance_pos = -1)]
    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        return ((RepoRow) row1).title.collate (((RepoRow) row2).title);
    }

    private struct AppEntry {
        string app_id;
        string github_suffix;
    }

    static AppEntry[] app_entries = {
        AppEntry () {
            app_id = "io.elementary.appcenter",
            github_suffix = "appcenter"
        },
        AppEntry () {
            app_id = "io.elementary.calculator",
            github_suffix = "calculator"
        },
        AppEntry () {
            app_id = "io.elementary.calendar",
            github_suffix = "calendar"
        },
        AppEntry () {
            app_id = "org.pantheon.camera",
            github_suffix = "camera"
        },
        AppEntry () {
            app_id = "io.elementary.code",
            github_suffix = "code"
        },
        AppEntry () {
            app_id = "io.elementary.files",
            github_suffix = "files"
        },
        AppEntry () {
            app_id = "org.pantheon.mail",
            github_suffix = "mail"
        },
        AppEntry () {
            app_id = "io.elementary.music",
            github_suffix = "music"
        },
        AppEntry () {
            app_id = "io.elementary.photos",
            github_suffix = "photos"
        },
        AppEntry () {
            app_id = "screenshot-tool",
            github_suffix = "screenshot-tool"
        },
        AppEntry () {
            app_id = "io.elementary.terminal",
            github_suffix = "terminal"
        },
        AppEntry () {
            app_id = "io.elementary.videos",
            github_suffix = "videos"
        }
    };

    private struct SystemEntry {
        string name;
        string github_suffix;
    }

    static SystemEntry[] system_entries = {
        SystemEntry () {
            name = _("Applications Menu"),
            github_suffix = "applications-menu"
        },
        SystemEntry () {
            name = _("Lock or Login Screen"),
            github_suffix = "greeter"
        },
        SystemEntry () {
            name = _("Look & Feel"),
            github_suffix = "stylesheet"
        },
        SystemEntry () {
            name = _("Multitasking or Window Management"),
            github_suffix = "gala"
        },
        SystemEntry () {
            name = _("Notifications"),
            github_suffix = "gala"
        }
    };

    private struct SwitchboardEntry {
        string name;
        string gettext_domain;
        string icon;
        string github_suffix;
    }

    static SwitchboardEntry[] switchboard_entries = {
        SwitchboardEntry () {
            name = "Applications",
            gettext_domain = "applications-plug",
            icon = "preferences-desktop-applications",
            github_suffix = "switchboard-plug-applications"
        },
        SwitchboardEntry () {
            name = "Desktop",
            gettext_domain = "pantheon-desktop-plug",
            icon = "preferences-desktop-wallpaper",
            github_suffix = "switchboard-plug-pantheon-shell"
        },
        SwitchboardEntry () {
            name = "Language & Region",
            gettext_domain = "locale-plug",
            icon = "preferences-desktop-locale",
            github_suffix = "switchboard-plug-locale"
        },
        SwitchboardEntry () {
            name = "Notifications",
            gettext_domain = "notifications-plug",
            icon = "preferences-system-notifications",
            github_suffix = "switchboard-plug-notifications"
        },
        SwitchboardEntry () {
            name = "Security & Privacy",
            gettext_domain = "pantheon-security-privacy-plug",
            icon = "preferences-system-privacy",
            github_suffix = "switchboard-plug-security-privacy"
        },
        SwitchboardEntry () {
            name = "Displays",
            gettext_domain = "pantheon-display-plug",
            icon = "preferences-desktop-display",
            github_suffix = "switchboard-plug-displays"
        },
        SwitchboardEntry () {
            name = "Keyboard",
            gettext_domain = "keyboard-plug",
            icon = "preferences-desktop-keyboard",
            github_suffix = "switchboard-plug-keyboard"
        },
        SwitchboardEntry () {
            name = "Mouse & Touchpad",
            gettext_domain = "mouse-touchpad-plug",
            icon = "preferences-desktop-peripherals",
            github_suffix = "switchboard-plug-mouse-touchpad"
        },
        SwitchboardEntry () {
            name = "Power",
            gettext_domain = "power-plug",
            icon = "preferences-system-power",
            github_suffix = "switchboard-plug-power"
        },
        SwitchboardEntry () {
            name = "Printers",
            gettext_domain = "printers-plug",
            icon = "printer",
            github_suffix = "switchboard-plug-printers"
        },
        SwitchboardEntry () {
            name = "Sound",
            gettext_domain = "sound-plug",
            icon = "preferences-desktop-sound",
            github_suffix = "switchboard-plug-sound"
        },
        SwitchboardEntry () {
            name = "Bluetooth",
            gettext_domain = "bluetooth-plug",
            icon = "preferences-bluetooth",
            github_suffix = "switchboard-plug-bluetooth"
        },
        SwitchboardEntry () {
            name = "Network",
            gettext_domain = "networking-plug",
            icon = "preferences-system-network",
            github_suffix = "switchboard-plug-networking"
        },
        SwitchboardEntry () {
            name = "Online Accounts",
            gettext_domain = "pantheon-online-accounts",
            icon = "preferences-desktop-online-accounts",
            github_suffix = "switchboard-plug-online-accounts"
        },
        SwitchboardEntry () {
            name = "Sharing",
            gettext_domain = "sharing-plug",
            icon = "preferences-system-sharing",
            github_suffix = "switchboard-plug-sharing"
        },
        SwitchboardEntry () {
            name = "About",
            gettext_domain = "about-plug",
            icon = "dialog-information",
            github_suffix = "switchboard-plug-about"
        },
        SwitchboardEntry () {
            name = "Date & Time",
            gettext_domain = "datetime-plug",
            icon = "preferences-system-time",
            github_suffix = "switchboard-plug-datetime"
        },
        SwitchboardEntry () {
            name = "Parental Control",
            gettext_domain = "parental-controls-plug",
            icon = "preferences-system-parental-controls",
            github_suffix = "switchboard-plug-parental-controls"
        },
        SwitchboardEntry () {
            name = "Universal Access",
            gettext_domain = "accessibility-plug",
            icon = "preferences-desktop-accessibility",
            github_suffix = "switchboard-plug-a11y"
        },
        SwitchboardEntry () {
            name = "User Accounts",
            gettext_domain = "useraccounts-plug",
            icon = "system-users",
            github_suffix = "switchboard-plug-accounts"
        }
    };

    private struct WingpanelEntry {
        string name;
        string gettext_domain;
        string icon;
        string github_suffix;
    }

    static WingpanelEntry[] wingpanel_entries = {
        WingpanelEntry () {
            name = "Bluetooth",
            gettext_domain = "bluetooth-plug",
            icon = "bluetooth-active-symbolic",
            github_suffix = "wingpanel-indicator-bluetooth"
        },
        WingpanelEntry () {
            name = "Date & Time",
            gettext_domain = "datetime-plug",
            icon = "appointment-symbolic",
            github_suffix = "wingpanel-indicator-datetime"
        },
        WingpanelEntry () {
            name = "Keyboard",
            gettext_domain = "keyboard-plug",
            icon = "input-keyboard-symbolic",
            github_suffix = "wingpanel-indicator-keyboard"
        },
        WingpanelEntry () {
            name = "Night Light",
            gettext_domain = "pantheon-display-plug",
            icon = "night-light-symbolic",
            github_suffix = "wingpanel-indicator-nightlight"
        },
        WingpanelEntry () {
            name = "Notifications",
            gettext_domain = "notifications-plug",
            icon = "notification-symbolic",
            github_suffix = "wingpanel-indicator-notifications"
        },
        WingpanelEntry () {
            name = "Power",
            gettext_domain = "power-plug",
            icon = "battery-full-symbolic",
            github_suffix = "wingpanel-indicator-power"
        },
        WingpanelEntry () {
            name = N_("Session"),
            gettext_domain = "about-plug",
            icon = "system-shutdown-symbolic",
            github_suffix = "wingpanel-indicator-session"
        },
        WingpanelEntry () {
            name = "Sound",
            gettext_domain = "sound-plug",
            icon = "audio-volume-high-symbolic",
            github_suffix = "wingpanel-indicator-sound"
        }
    };

    private enum Category {
        DEFAULT_APPS,
        PANEL,
        SETTINGS,
        SYSTEM;

        public string to_string () {
            switch (this) {
                case PANEL:
                    return _("Panel Indicators");
                case SETTINGS:
                    return _("System Settings");
                case SYSTEM:
                    return _("Desktop Components");
                default:
                    return _("Default Apps");
            }
        }
    }

    private class CategoryRow : Gtk.ListBoxRow {
        public Category category { get; construct; }

        public CategoryRow (Category category) {
            Object (category: category);
        }

        construct {
            var label = new Gtk.Label (category.to_string ());
            label.hexpand = true;
            label.xalign = 0;

            var caret = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = grid.margin_end = 6;
            grid.add (label);
            grid.add (caret);

            add (grid);
        }
    }

    private class RepoRow : Gtk.ListBoxRow {
        public bool selected { get; set; }
        public Category category { get; construct; }
        public GLib.Icon? icon { get; construct; }
        public string title { get; construct; }
        public string url { get; construct; }

        public RepoRow (string title, GLib.Icon? icon, Category category, string url) {
            Object (
                category: category,
                icon: icon,
                title: title,
                url: url
            );
        }

        construct {
            var label = new Gtk.Label (title);
            label.hexpand = true;
            label.xalign = 0;

            var selection_icon = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU);
            selection_icon.no_show_all = true;
            selection_icon.visible = false;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.margin = 3;
            grid.margin_start = grid.margin_end = 6;

            if (icon != null) {
                var icon = new Gtk.Image.from_gicon (icon, Gtk.IconSize.LARGE_TOOLBAR);
                icon.pixel_size = 24;
                grid.add (icon);
            }
            grid.add (label);
            grid.add (selection_icon);

            add (grid);

            notify["selected"].connect (() => {
                selection_icon.visible = selected;
            });
        }
    }
}
