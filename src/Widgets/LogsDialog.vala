/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.LogRow : Granite.Bin {
    private Gtk.Label origin;
    private Gtk.Label message;

    construct {
        origin = new Gtk.Label (null);
        message = new Gtk.Label (null) {
            ellipsize = END,
            hexpand = true,
            halign = START,
            single_line_mode = true,
        };

        var box = new Gtk.Box (HORIZONTAL, 6);
        box.append (origin);
        box.append (message);

        child = box;
    }

    public void bind (SystemdLogEntry entry) {
        origin.label = entry.origin;
        message.label = entry.message;
    }
}

public class About.LogsDialog : Granite.Dialog {
    private SystemdLogModel model;

    construct {
        title = _("System Logs");
        modal = true;
        default_height = 500;
        default_width = 500;

        var title_label = new Gtk.Label (
            _("System Logs")
        ) {
            hexpand = true,
            xalign = 0
        };
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var refresh_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic") {
            tooltip_text = _("Load new entries")
        };

        var top_box = new Gtk.Box (HORIZONTAL, 6);
        top_box.append (title_label);
        top_box.append (refresh_button);

        var search_entry = new Gtk.SearchEntry ();

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup);
        factory.bind.connect (bind);

        model = new SystemdLogModel ();

        var selection_model = new Gtk.NoSelection (model);

        var list_view = new Gtk.ListView (selection_model, factory);

        var scrolled = new Gtk.ScrolledWindow () {
            child = list_view,
            hscrollbar_policy = NEVER,
            max_content_height = 400,
            propagate_natural_height = true
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled
        };

        var box = new Gtk.Box (VERTICAL, 12);
        box.append (top_box);
        box.append (search_entry);
        box.append (frame);

        get_content_area ().append (box);

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        refresh_button.clicked.connect (model.refresh);
        search_entry.search_changed.connect (on_search_changed);

        response.connect (() => close ());
    }

    private void setup (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new LogRow ();
    }

    private void bind (Object obj) {
        var item = (Gtk.ListItem) obj;
        var entry = (SystemdLogEntry) item.item;
        var row = (LogRow) item.child;
        row.bind (entry);
    }

    private void on_search_changed (Gtk.SearchEntry entry) {
        model.search (entry.text);
    }
}
