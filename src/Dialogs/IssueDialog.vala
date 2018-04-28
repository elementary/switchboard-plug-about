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
            {_("AppCenter"), "appcenter"},
            {_("Calculator"), "calculator"},
            {_("Calendar"), "calendar"},
            {_("Camera"), "camera"},
            {_("Code"), "code"},
            {_("Files"), "files"},
            {_("Mail"), "mail"},
            {_("Music"), "music"},
            {_("Photos"), "photos"},
            {_("Screenshot"), "screenshot-tool"},
            {_("Terminal"), "terminal"},
            {_("Videos"), "videos"},
            {_("Applications Menu"), "applications-menu"},
            {_("Lock or Login Screen"), "greeter"},
            {_("Look & Feel"), "stylesheet"},
            {_("Multitasking or Window Management"), "gala"},
            {_("Notifications"), "gala"},
            {_("Bluetooth Indicator"), "wingpanel-indicator-bluetooth"},
            {_("Date & Time Indicator"), "wingpanel-indicator-datetime"},
            {_("Keyboard Indicator"), "wingpanel-indicator-keyboard"},
            {_("Night Light Indicator"), "wingpanel-indicator-nightlight"},
            {_("Notifications Indicator"), "wingpanel-indicator-notifications"},
            {_("Power Indicator"), "wingpanel-indicator-power"},
            {_("Session Indicator"), "wingpanel-indicator-session"},
            {_("Sound Indicator"), "wingpanel-indicator-sound"},
            {_("System Settings → Applications"), "switchboard-plug-applications"},
            {_("System Settings → Desktop"), "switchboard-plug-pantheon-shell"},
            {_("System Settings → Language & Region"), "switchboard-plug-locale"},
            {_("System Settings → Notifications"), "switchboard-plug-notifications"},
            {_("System Settings → Security & Privacy"), "switchboard-plug-security-privacy"},
            {_("System Settings → Displays"), "switchboard-plug-displays"},
            {_("System Settings → Keyboard"), "switchboard-plug-keyboard"},
            {_("System Settings → Mouse & Touchpad"), "switchboard-plug-mouse-touchpad"},
            {_("System Settings → Power"), "switchboard-plug-power"},
            {_("System Settings → Printers"), "switchboard-plug-printers"},
            {_("System Settings → Sound"), "switchboard-plug-sound"},
            {_("System Settings → Bluetooth"), "switchboard-plug-bluetooth"},
            {_("System Settings → Network"), "switchboard-plug-networking"},
            {_("System Settings → Online Accounts"), "switchboard-plug-online-accounts"},
            {_("System Settings → Sharing"), "switchboard-plug-sharing"},
            {_("System Settings → About"), "switchboard-plug-about"},
            {_("System Settings → Date & Time"), "switchboard-plug-datetime"},
            {_("System Settings → Parental Control"), "switchboard-plug-parental-controls"},
            {_("System Settings → Universal Access"), "switchboard-plug-a11y"},
            {_("System Settings → User Accounts"), "switchboard-plug-accounts"}
        };
    }

    construct {
        listbox = new Gtk.ListBox ();
        listbox.expand = true;

        for (int i = 0; i < repo_info.length[0]; i++) {
            var repo_row = new RepoRow (repo_info[i, 0], repo_info[i, 1]);
            listbox.add (repo_row);
        }

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (listbox);

        var frame = new Gtk.Frame (null);
        frame.add (scrolled);

        custom_bin.add (frame);
        custom_bin.show_all ();

        height_request = 500;

        add_button ("Cancel", Gtk.ResponseType.CANCEL);

        var report_button = add_button ("Report Problem", 0);
        report_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        listbox.selected_rows_changed.connect (() => {
            foreach (var repo_row in listbox.get_children ()) {
                ((RepoRow) repo_row).selected = false;
            }
            ((RepoRow) listbox.get_selected_row ()).selected = true;
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

    private class RepoRow : Gtk.ListBoxRow {
        public bool selected { get; set; }
        public string title { get; construct; }
        public string url { get; construct; }

        public RepoRow (string title, string url) {
            Object (
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
