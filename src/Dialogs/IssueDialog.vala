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
            {_("AppCenter"), "default-apps", "appcenter"},
            {_("Calculator"), "default-apps", "calculator"},
            {_("Calendar"), "default-apps", "calendar"},
            {_("Camera"), "default-apps", "camera"},
            {_("Code"), "default-apps", "code"},
            {_("Files"), "default-apps", "files"},
            {_("Mail"), "default-apps", "mail"},
            {_("Music"), "default-apps", "music"},
            {_("Photos"), "default-apps", "photos"},
            {_("Screenshot"), "default-apps", "screenshot-tool"},
            {_("Terminal"), "default-apps", "terminal"},
            {_("Videos"), "default-apps", "videos"},
            {_("Applications Menu"), "system", "applications-menu"},
            {_("Lock or Login Screen"), "system", "greeter"},
            {_("Look & Feel"), "system", "stylesheet"},
            {_("Multitasking or Window Management"), "system", "gala"},
            {_("Notifications"), "system", "gala"},
            {_("Bluetooth"), "panel", "wingpanel-indicator-bluetooth"},
            {_("Date & Time"), "panel", "wingpanel-indicator-datetime"},
            {_("Keyboard"), "panel", "wingpanel-indicator-keyboard"},
            {_("Night Light"), "panel", "wingpanel-indicator-nightlight"},
            {_("Notifications"), "panel", "wingpanel-indicator-notifications"},
            {_("Power"), "panel", "wingpanel-indicator-power"},
            {_("Session"), "panel", "wingpanel-indicator-session"},
            {_("Sound Indicator"), "panel", "wingpanel-indicator-sound"},
            {_("Applications"), "settings", "switchboard-plug-applications"},
            {_("Desktop"), "settings", "switchboard-plug-pantheon-shell"},
            {_("Language & Region"), "settings", "switchboard-plug-locale"},
            {_("Notifications"), "settings", "switchboard-plug-notifications"},
            {_("Security & Privacy"), "settings", "switchboard-plug-security-privacy"},
            {_("Displays"), "settings", "switchboard-plug-displays"},
            {_("Keyboard"), "settings", "switchboard-plug-keyboard"},
            {_("Mouse & Touchpad"), "settings", "switchboard-plug-mouse-touchpad"},
            {_("Power"), "settings", "switchboard-plug-power"},
            {_("Printers"), "settings", "switchboard-plug-printers"},
            {_("Sound"), "settings", "switchboard-plug-sound"},
            {_("Bluetooth"), "settings", "switchboard-plug-bluetooth"},
            {_("Network"), "settings", "switchboard-plug-networking"},
            {_("Online Accounts"), "settings", "switchboard-plug-online-accounts"},
            {_("Sharing"), "settings", "switchboard-plug-sharing"},
            {_("About"), "settings", "switchboard-plug-about"},
            {_("Date & Time"), "settings", "switchboard-plug-datetime"},
            {_("Parental Control"), "settings", "switchboard-plug-parental-controls"},
            {_("Universal Access"), "settings", "switchboard-plug-a11y"},
            {_("User Accounts"), "settings", "switchboard-plug-accounts"}
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
            var repo_row = new RepoRow (repo_info[i, 0], repo_info[i, 1], repo_info[i, 2]);
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
        public string title { get; construct; }
        public string url { get; construct; }

        public RepoRow (string title, string category, string url) {
            Object (
                category: category,
                title: title,
                url: url
            );
        }

        construct {
            var label = new Gtk.Label (title);
            label.hexpand = true;
            label.xalign = 0;

            var icon = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU);
            icon.no_show_all = true;
            icon.visible = false;

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = grid.margin_end = 6;
            grid.add (label);
            grid.add (icon);

            add (grid);

            notify["selected"].connect (() => {
                icon.visible = selected;
            });
        }
    }
}
