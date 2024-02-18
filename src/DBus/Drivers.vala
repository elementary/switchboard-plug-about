/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

[DBus (name="io.elementary.settings_daemon.Drivers")]
public interface Drivers : Object {
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
    }

    public signal void state_changed ();

    public abstract async CurrentState get_current_state () throws DBusError, IOError;
    public abstract async HashTable<string, HashTable<string, bool>> get_available_drivers () throws DBusError, IOError;
    public abstract async void cancel () throws DBusError, IOError;
    public abstract async void check_for_drivers (bool notify) throws DBusError, IOError;
    public abstract async void install (string name) throws DBusError, IOError;
}
