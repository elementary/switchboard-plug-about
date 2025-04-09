/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.LogRow : Granite.Bin {
    private Gtk.Label sender;
    private Gtk.Label message;

    construct {
        sender = new Gtk.Label (null);
        message = new Gtk.Label (null) {
            wrap = true,
            hexpand = true,
            halign = START,
        };

        var box = new Gtk.Box (HORIZONTAL, 6);
        box.append (sender);
        box.append (message);

        child = box;
    }

    public void bind (SystemdLogEntry row) {
        row.bind_property ("origin", sender, "label", SYNC_CREATE);
        row.bind_property ("message", message, "label", SYNC_CREATE);
        row.queue_load ();
    }
}

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

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup);
        factory.bind.connect (bind);

        var selection_model = new Gtk.NoSelection (new About.SystemdLogModel ());

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
        box.append (title_label);
        box.append (frame);

        get_content_area ().append (box);

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        response.connect (() => {
            close ();
        });
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
}
