public class About.DriverRow : Gtk.ListBoxRow {
    public signal void install ();

    public string driver_name { get; construct; }
    public bool installed { get; construct; }

    public DriverRow (string driver_name, bool installed) {
        Object (driver_name: driver_name, installed: installed);
    }

    construct {
        var icon = new Gtk.Image.from_icon_name ("application-x-firmware") {
            pixel_size = 32
        };

        var label = new Gtk.Label (driver_name) {
            hexpand = true,
            xalign = 0
        };

        var install_button = new Gtk.Button.with_label (installed ? _("Installed") : _("Install")) {
            sensitive = !installed,
            valign = CENTER
        };

        var box = new Gtk.Box (HORIZONTAL, 6);
        box.append (icon);
        box.append (label);
        box.append (install_button);

        child = box;

        install_button.clicked.connect (() => install ());
    }
}