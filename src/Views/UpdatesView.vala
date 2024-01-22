[DBus (name="io.elementary.settings_daemon.SystemUpdate")]
public interface SystemUpdate : Object {
    public enum State {
        UP_TO_DATE,
        CHECKING,
        AVAILABLE,
        DOWNLOADING,
        RESTART_REQUIRED
    }

    public struct CurrentState {
        State state;
        string message;
    }

    public struct UpdateDetails {
        string[] packages;
        int size;
    }

    public signal void state_changed ();

    public abstract async CurrentState get_current_state () throws DBusError, IOError;
    public abstract async UpdateDetails get_update_details () throws DBusError, IOError;
    public abstract async void update () throws DBusError, IOError;
    public abstract async void check_for_updates (bool force = false) throws DBusError, IOError;
}

public class About.UpdatesView : Granite.SimpleSettingsPage {
    private Gtk.StringList updates;
    private SystemUpdate? update_proxy = null;
    private Granite.Placeholder checking_alert_view;
    private Granite.Placeholder up_to_date_alert_view;
    private Gtk.ListBox update_list;
    private Gtk.Stack button_stack;
    private Granite.OverlayBar status_bar;
    private Gtk.InfoBar reboot_infobar;

    public UpdatesView () {
        Object (
            icon_name: "system-software-update",
            title: _("Updates"),
            description: _("System updates.")
        );
    }

    construct {
        updates = new Gtk.StringList (null);

        reboot_infobar = new Gtk.InfoBar () {
            revealed = false,
            message_type = WARNING
        };
        reboot_infobar.add_child (new Gtk.Label (_("A restart is required to finish installing updates")));

        checking_alert_view = new Granite.Placeholder (_("Checking for Updates")) {
            description = _("Connecting to the backend and searching for updates."),
            icon = new ThemedIcon ("sync-synchronizing")
        };

        up_to_date_alert_view = new Granite.Placeholder (_("Up To Date")) {
            description = _("No updates available."),
            icon = new ThemedIcon ("emblem-default")
        };

        update_list = new Gtk.ListBox () {
            vexpand = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };
        update_list.set_placeholder (up_to_date_alert_view);
        update_list.bind_model (updates, (obj) => {
            var str = ((Gtk.StringObject) obj).string;
            return new Gtk.Label (str) {
                halign = START,
                valign = CENTER,
                margin_start = 6,
                margin_top = 3
            };
        });

        var update_scrolled = new Gtk.ScrolledWindow () {
            child = update_list
        };

        var stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };
        stack.add_child (update_scrolled);

        var overlay = new Gtk.Overlay () {
            child = stack
        };

        status_bar = new Granite.OverlayBar (overlay) {
            visible = false,
            active = true
        };

        var frame = new Gtk.Frame (null) {
            child = overlay
        };

        content_area.attach (frame, 0, 0);
        content_area.attach (reboot_infobar, 0, 1);

        var check_button = new Gtk.Button.with_label (_("Check for updates"));

        var update_button = new Gtk.Button.with_label (_("Download"));
        update_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var blank = new Gtk.Grid ();

        button_stack = new Gtk.Stack () {
            transition_type = CROSSFADE
        };
        button_stack.add_named (check_button, "check");
        button_stack.add_named (update_button, "update");
        button_stack.add_named (blank, "blank");

        action_area.append (button_stack);

        Bus.get_proxy.begin<SystemUpdate> (SESSION, "io.elementary.settings-daemon", "/io/elementary/settings_daemon", 0, null, (obj, res) => {
            try {
                update_proxy = Bus.get_proxy.end (res);

                update_proxy.state_changed.connect (update_state);
                update_state.begin ();
            } catch (Error e) {
                critical ("Failed to get updates proxy");
            }
        });

        update_button.clicked.connect (() => {
            if (update_proxy != null) {
                update_proxy.update.begin ((obj, res) => {
                    try {
                        update_proxy.update.end (res);
                    } catch (Error e) {
                        critical ("Failed to update: %s", e.message);
                    }
                });
            }
        });

        check_button.clicked.connect (() => {
            if (update_proxy != null) {
                update_proxy.check_for_updates.begin (false, (obj, res) => {
                    try {
                        update_proxy.update.end (res);
                    } catch (Error e) {
                        critical ("Failed to check for updates: %s", e.message);
                    }
                });
            }
        });
    }

    private async void update_state () {
        if (update_proxy == null) {
            return;
        }

        SystemUpdate.CurrentState current_state;
        try {
            current_state = yield update_proxy.get_current_state ();
        } catch (Error e) {
            critical ("Failed to get current state from Updates Backend: %s", e.message);
            return;
        }

        switch (current_state.state) {
            case UP_TO_DATE:
                status_bar.visible = false;
                update_list.set_placeholder (up_to_date_alert_view);
                button_stack.visible_child_name = "check";
                break;
            case CHECKING:
                status_bar.visible = true;
                status_bar.label = current_state.message;
                update_list.set_placeholder (checking_alert_view);
                button_stack.visible_child_name = "blank";
                break;
            case AVAILABLE:
                status_bar.visible = false;
                try {
                    var details = yield update_proxy.get_update_details ();
                    updates.splice (0, updates.get_n_items (), details.packages);
                    button_stack.visible_child_name = "update";
                } catch (Error e) {
                    warning ("Failed to get updates list from backend: %s", e.message);
                }
                break;
            case DOWNLOADING:
                status_bar.visible = true;
                status_bar.label = current_state.message;
                button_stack.visible_child_name = "blank";
                break;
            case RESTART_REQUIRED:
                reboot_infobar.revealed = true;
                status_bar.visible = false;
                button_stack.visible_child_name = "blank";
                break;
        }
    }
}
