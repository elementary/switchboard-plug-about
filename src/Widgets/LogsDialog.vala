/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.LogsDialog : Granite.Dialog {

    public LogsDialog () {
    }

    construct {
        title = _("System Logs");
        modal = true;

        var title_label = new Gtk.Label (
            _("System Logs")
        ) {
            halign = START
        };
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var log_listbox = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = NONE
        };
        var model = new About.SystemdLogModel ();
        log_listbox.bind_model (model, (obj) => {
            unowned var row = (About.SystemdLogRow) obj;

            var origin_label = new Gtk.Label (row.origin);
            origin_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
            var message_label = new Gtk.Label (row.message) {
                wrap = true,
                hexpand = true,
                halign = START,
            };

            var box = new Gtk.Box (HORIZONTAL, 6);
            box.append (origin_label);
            box.append (message_label);

            return box;
        });

        var scrolled = new Gtk.ScrolledWindow () {
            child = log_listbox,
            hscrollbar_policy = NEVER,
            max_content_height = 400,
            propagate_natural_height = true
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled
        };

        var box = new Gtk.Box (VERTICAL, 12);
        box.append (title_label);
        box.append (frame);

        get_content_area ().append (box);

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        response.connect (() => {
            close ();
        });
    }
}
