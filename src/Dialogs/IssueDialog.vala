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
            {_("Music"), "music"},
            {_("System Settings → Applications"), "switchboard-plug-applications"},
            {_("System Settings → Language & Region"), "switchboard-plug-locale"}
            
        };
    }

    construct {
        listbox = new Gtk.ListBox ();
        listbox.expand = true;

        for (int i = 0; i < repo_info.length[0]; i++) {
            var repo_row = new RepoRow (repo_info[i, 0], repo_info[i, 1]);
            listbox.add (repo_row);
        }

        var frame = new Gtk.Frame (null);
        frame.add (listbox);

        custom_bin.add (frame);
        custom_bin.show_all ();

        add_button ("Cancel", Gtk.ResponseType.CANCEL);
        add_button ("Report Problem", 0);

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
