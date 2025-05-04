/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
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
