/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.UpdateDetailsDialog : Granite.Dialog {
    public Gtk.StringList packages { get; construct; }

    public UpdateDetailsDialog (Gtk.StringList packages ) {
        Object (packages: packages);
    }

    construct {
        title = _("What's New");
        modal = true;

        var title_label = new Gtk.Label (
            ngettext (
                "%u package will be upgraded",
                "%u packages will be upgraded",
                packages.get_n_items ()
            ).printf (packages.get_n_items ())
        ) {
            halign = START
        };
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var packages_listbox = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = NONE
        };
        packages_listbox.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        packages_listbox.bind_model (packages, (obj) => {
            var str = ((Gtk.StringObject) obj).string;

            var image = new Gtk.Image.from_icon_name ("package-x-generic") {
                icon_size = LARGE
            };

            var label = new Gtk.Label (str);

            var box = new Gtk.Box (HORIZONTAL, 6);
            box.append (image);
            box.append (label);

            return box;
        });

        var scrolled = new Gtk.ScrolledWindow () {
            child = packages_listbox,
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
