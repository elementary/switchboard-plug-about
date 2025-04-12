/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class About.LogDetailsView : Adw.NavigationPage {
    public SystemdLogEntry entry {
        set {
            origin.label = value.origin;
            timestamp.label = value.dt.format ("%s %s".printf (
                Granite.DateTime.get_default_date_format (),
                Granite.DateTime.get_default_time_format (false, true)
            ));
            message.label = value.message;
            title = value.origin;
        }
    }

    private Gtk.Label origin;
    private Gtk.Label timestamp;
    private Gtk.Label message;

    construct {
        var origin_label = new Gtk.Label (_("Sender:")) {
            halign = END
        };
        origin_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        origin = new Gtk.Label (null) {
            halign = START,
            wrap = true,
            wrap_mode = WORD_CHAR
        };

        var timestamp_label = new Gtk.Label (_("Timestamp:")) {
            halign = END
        };
        timestamp_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        timestamp = new Gtk.Label (null) {
            halign = START,
            wrap = true,
            wrap_mode = WORD_CHAR
        };

        var message_label = new Gtk.Label (_("Message:")) {
            halign = END
        };
        message_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        message = new Gtk.Label (null) {
            halign = START,
            wrap = true,
            wrap_mode = WORD_CHAR
        };

        var grid = new Gtk.Grid () {
            column_spacing = 3,
            row_spacing = 6,
            margin_start = 6,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = CENTER
        };
        grid.attach (origin_label, 0, 0);
        grid.attach (origin, 1, 0);
        grid.attach (timestamp_label, 0, 1);
        grid.attach (timestamp, 1, 1);
        grid.attach (message_label, 0, 2);
        grid.attach (message, 1, 2);

        var scrolled = new Gtk.ScrolledWindow () {
            child = grid
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled,
            top_bar_style = RAISED
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;
    }
}
