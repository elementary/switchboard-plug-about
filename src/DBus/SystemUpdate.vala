[DBus (name="io.elementary.settings_daemon.SystemUpdate")]
public interface SystemUpdate : Object {
    public enum State {
        UP_TO_DATE,
        CHECKING,
        AVAILABLE,
        DOWNLOADING,
        RESTART_REQUIRED,
        ERROR
    }

    public struct CurrentState {
        State state;
        string message;
        uint percentage;
        uint64 download_size_remaining;
    }

    public struct UpdateDetails {
        string[] packages;
        uint64 size;
        Pk.Info[] info;
    }

    public signal void state_changed ();

    public abstract async CurrentState get_current_state () throws DBusError, IOError;
    public abstract async UpdateDetails get_update_details () throws DBusError, IOError;
    public abstract async void cancel () throws DBusError, IOError;
    public abstract async void check_for_updates (bool force, bool notify) throws DBusError, IOError;
    public abstract async void update () throws DBusError, IOError;
    public abstract async int64 get_last_refresh_time () throws DBusError, IOError;
}
