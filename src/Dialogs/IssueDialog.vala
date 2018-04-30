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
    private static string[,] repo_info;
    private Gtk.ListBox listbox;
    private string? category_filter;

    public IssueDialog () {
        Object (
            image_icon: new ThemedIcon ("dialog-question"), 
            primary_text: _("Which of the Following Are You Seeing an Issue With?"),
            secondary_text: _("Please select a component from the list."),
            resizable: true,
            modal: true
        );
    }

    static construct {
        repo_info = {
            {_("AppCenter"), "system-software-install", "default-apps", "appcenter"},
            {_("Calculator"), "accessories-calculator", "default-apps", "calculator"},
            {_("Calendar"), "office-calendar", "default-apps", "calendar"},
            {_("Camera"), "accessories-camera", "default-apps", "camera"},
            {_("Code"), "io.elementary.code", "default-apps", "code"},
            {_("Files"), "system-file-manager", "default-apps", "files"},
            {_("Mail"), "internet-mail", "default-apps", "mail"},
            {_("Music"), "multimedia-audio-player", "default-apps", "music"},
            {_("Photos"), "multimedia-photo-manager", "default-apps", "photos"},
            {_("Screenshot"), "accessories-screenshot", "default-apps", "screenshot-tool"},
            {_("Terminal"), "utilities-terminal", "default-apps", "terminal"},
            {_("Videos"), "multimedia-video-player", "default-apps", "videos"},
            {_("Applications Menu"), "", "system", "applications-menu"},
            {_("Lock or Login Screen"), "", "system", "greeter"},
            {_("Look & Feel"), "system", "", "stylesheet"},
            {_("Multitasking or Window Management"), "", "system", "gala"},
            {_("Notifications"), "", "system", "gala"},
            {_("Bluetooth"), "bluetooth-active-symbolic", "panel", "wingpanel-indicator-bluetooth"},
            {_("Date & Time"), "appointment-symbolic", "panel", "wingpanel-indicator-datetime"},
            {_("Keyboard"), "input-keyboard-symbolic", "panel", "wingpanel-indicator-keyboard"},
            {_("Night Light"), "night-light-symbolic", "panel", "wingpanel-indicator-nightlight"},
            {_("Notifications"), "notification-symbolic", "panel", "wingpanel-indicator-notifications"},
            {_("Power"), "battery-full-symbolic", "panel", "wingpanel-indicator-power"},
            {_("Session"), "system-shutdown-symbolic", "panel", "wingpanel-indicator-session"},
            {_("Sound"), "audio-volume-high-symbolic", "panel", "wingpanel-indicator-sound"},
            {_("Applications"), "preferences-desktop-applications", "settings", "switchboard-plug-applications"},
            {_("Desktop"), "preferences-desktop-wallpaper", "settings", "switchboard-plug-pantheon-shell"},
            {_("Language & Region"), "preferences-desktop-locale", "settings", "switchboard-plug-locale"},
            {_("Notifications"), "preferences-system-notifications", "settings", "switchboard-plug-notifications"},
            {_("Security & Privacy"), "preferences-system-privacy", "settings", "switchboard-plug-security-privacy"},
            {_("Displays"), "preferences-desktop-display", "settings", "switchboard-plug-displays"},
            {_("Keyboard"), "preferences-desktop-keyboard", "settings", "switchboard-plug-keyboard"},
            {_("Mouse & Touchpad"), "preferences-desktop-peripherals", "settings", "switchboard-plug-mouse-touchpad"},
            {_("Power"), "preferences-system-power", "settings", "switchboard-plug-power"},
            {_("Printers"), "printer", "settings", "switchboard-plug-printers"},
            {_("Sound"), "preferences-desktop-sound", "settings", "switchboard-plug-sound"},
            {_("Bluetooth"), "preferences-bluetooth", "settings", "switchboard-plug-bluetooth"},
            {_("Network"), "preferences-system-network", "settings", "switchboard-plug-networking"},
            {_("Online Accounts"), "preferences-desktop-online-accounts", "settings", "switchboard-plug-online-accounts"},
            {_("Sharing"), "preferences-system-sharing", "settings", "switchboard-plug-sharing"},
            {_("About"), "dialog-information", "settings", "switchboard-plug-about"},
            {_("Date & Time"), "preferences-system-time", "settings", "switchboard-plug-datetime"},
            {_("Parental Control"), "preferences-system-parental-controls", "settings", "switchboard-plug-parental-controls"},
            {_("Universal Access"), "preferences-desktop-accessibility", "settings", "switchboard-plug-a11y"},
            {_("User Accounts"), "system-users", "settings", "switchboard-plug-accounts"}
        };
    }

    construct {
        var apps_category = new CategoryRow (_("Default Apps"), "default-apps");
        var panel_category = new CategoryRow (_("Panel Indicators"), "panel");
        var settings_category = new CategoryRow (_("System Settings"), "settings");
        var system_category = new CategoryRow (_("Desktop Components"), "system");

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
        listbox.set_filter_func ((Gtk.ListBoxFilterFunc) filter_function);

        for (int i = 0; i < repo_info.length[0]; i++) {
            var repo_row = new RepoRow (repo_info[i, 0], repo_info[i, 1], repo_info[i, 2], repo_info[i, 3]);
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

        add_button ("Cancel", Gtk.ResponseType.CANCEL);

        var report_button = add_button ("Report Problem", 0);
        report_button.sensitive = false;
        report_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        category_list.row_activated.connect ((row) => {
            stack.visible_child = repo_list_grid;
            category_filter = ((CategoryRow) row).category;
            category_title.label = ((CategoryRow) row).title;
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
                AppInfo.launch_default_for_uri ("https://github.com/elementary/%s/issues/new".printf (url), null);
            } catch (Error e) {
                critical (e.message);
            }
        }

        destroy ();
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (RepoRow row) {
        if (row.category == category_filter) {
            return true;
        }
        return false;
    }

    private class CategoryRow : Gtk.ListBoxRow {
        public string category { get; construct; }
        public string title { get; construct; }

        public CategoryRow (string title, string category) {
            Object (
                category: category,
                title: title
            );
        }

        construct {
            var label = new Gtk.Label (title);
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
        public string category { get; construct; }
        public string icon_name { get; construct; }
        public string title { get; construct; }
        public string url { get; construct; }

        public RepoRow (string title, string icon_name, string category, string url) {
            Object (
                category: category,
                icon_name: icon_name,
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

            if (icon_name != "") {
                var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);
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
