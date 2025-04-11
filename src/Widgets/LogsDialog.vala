/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.LogCell : Granite.Bin {
    public enum CellType {
        ORIGIN,
        MESSAGE
    }

    public CellType cell_type { get; construct; }

    private Gtk.Label label;

    public LogCell (CellType cell_type) {
        Object (cell_type: cell_type);
    }

    construct {
        label = new Gtk.Label (null) {
            ellipsize = END,
            single_line_mode = true,
            halign = START,
        };

        if (cell_type == ORIGIN) {
            label.max_width_chars = 10;
            label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        }

        child = label;
    }

    public void bind (SystemdLogEntry entry) {
        switch (cell_type) {
            case ORIGIN:
                label.label = entry.origin;
                break;
            case MESSAGE:
                label.label = entry.message;
                break;
        }
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

        model = new SystemdLogModel ();

        var selection_model = new Gtk.NoSelection (model);

        var header_factory = new Gtk.SignalListItemFactory ();
        header_factory.setup.connect (setup_header);
        header_factory.bind.connect (bind_header);

        var origin_factory = new Gtk.SignalListItemFactory ();
        origin_factory.setup.connect (setup_origin);
        origin_factory.bind.connect (bind);

        var origin_column = new Gtk.ColumnViewColumn (_("Sender"), origin_factory);

        var message_factory = new Gtk.SignalListItemFactory ();
        message_factory.setup.connect (setup_message);
        message_factory.bind.connect (bind);

        var message_column = new Gtk.ColumnViewColumn (_("Message"), message_factory) {
            expand = true
        };

        var column_view = new Gtk.ColumnView (selection_model) {
            header_factory = header_factory,
        };
        column_view.append_column (origin_column);
        column_view.append_column (message_column);

        var scrolled = new Gtk.ScrolledWindow () {
            child = column_view,
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
        scrolled.edge_reached.connect (on_edge_reached);

        response.connect (() => close ());
    }

    private void setup_header (Object obj) {
        var item = (Gtk.ListHeader) obj;
        item.child = new Gtk.Label (null) {
            halign = START,
            use_markup = true
        };
    }

    private void bind_header (Object obj) {
        var item = (Gtk.ListHeader) obj;
        var entry = (SystemdLogEntry) item.item;
        var label = (Gtk.Label) item.child;
        label.label = "<b>%s</b>".printf (entry.formatted_time);
    }

    private void setup_origin (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new LogCell (ORIGIN);
    }

    private void setup_message (Object obj) {
        var item = (Gtk.ListItem) obj;
        item.child = new LogCell (MESSAGE);
    }

    private void bind (Object obj) {
        var item = (Gtk.ListItem) obj;
        var entry = (SystemdLogEntry) item.item;
        var cell = (LogCell) item.child;
        cell.bind (entry);
    }

    private void on_search_changed (Gtk.SearchEntry entry) {
        model.search (entry.text);
    }

    private void on_edge_reached (Gtk.PositionType pos) {
        if (pos == BOTTOM) {
            model.load_chunk ();
        }
    }
}
