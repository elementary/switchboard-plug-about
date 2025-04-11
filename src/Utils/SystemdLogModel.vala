/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.SystemdLogEntry : GLib.Object {
    public string origin { get; construct; }
    public string message { get; construct; }

    public SystemdLogEntry (string origin, string message) {
        Object (origin: origin, message: message);
    }

    public bool matches (string term) {
        return origin.contains (term) || message.contains (term);
    }
}

public class About.SystemdLogModel : GLib.Object, GLib.ListModel {
    private const int CHUNK_SIZE = 200;
    private const int64 CHUNK_TIME = 1000; // 1 millisecond

    private Systemd.Journal journal;
    private string current_boot_id;
    private uint64 current_tail = 0;
    private string current_search_term = "";

    private Gee.ArrayList<SystemdLogEntry> entries;
    private bool eof = false;

    construct {
        entries = new Gee.ArrayList<SystemdLogEntry> ();

        int res = Systemd.Journal.open_namespace (out journal, null, LOCAL_ONLY);
        if (res != 0) {
            critical ("%s", strerror(-res));
            return;
        }

        Systemd.Id128 boot_id;
        res = Systemd.Id128.boot (out boot_id);
        if (res != 0) {
            critical ("%s", strerror(-res));
            return;
        }

        current_boot_id = boot_id.str;

        init ();
    }

    private void reset () {
        if (!entries.is_empty) {
            var removed = entries.size;
            entries.clear ();
            items_changed (0, removed, 0);
        }

        eof = false;
        journal.flush_matches ();
    }

    private void init () {
        //TODO: Add exact matches, allow to filter by boot
        journal.add_match ("_BOOT_ID=%s".printf(current_boot_id).data);
        journal.add_conjunction ();

        if (current_tail == 0) {
            journal.seek_tail ();
            journal.previous ();
            int res = journal.get_realtime_usec (out current_tail);
            if (res != 0) {
                critical ("Failed to get tail realtime: %s", strerror(-res));
                return;
            }
        } else {
            journal.seek_realtime_usec (current_tail);
            journal.previous ();
        }

        load_chunk ();
    }

    private void load_chunk () {
        if (eof) {
            return;
        }

        var start_items = get_n_items ();

        Idle.add (() => {
            load_timed ();
            return !eof && get_n_items () - start_items < CHUNK_SIZE ? Source.CONTINUE : Source.REMOVE;
        });
    }

    private void load_timed () {
        if (eof) {
            return;
        }

        var start_time = get_monotonic_time ();

        while (get_monotonic_time () - start_time < CHUNK_TIME) {
            if (!load_next_entry ()) {
                eof = true;
                break;
            }
        }
    }

    private bool load_next_entry () {
        int res = journal.previous ();
        if (res == 0) {
            return false;
        }

        if (res < 0) {
            critical ("Failed to go to next aka previous entry: %s", strerror (-res));
            return false;
        }

        unowned uint8[] data;
        unowned uint8[] comm_data;
        res = journal.get_data ("MESSAGE", out data);
        if (res != 0) {
            critical ("Failed to get message: %s", strerror (-res));
            return true; // Don't eof just skip it
        }

        res = journal.get_data ("_COMM", out comm_data);
        if (res != 0) {
            critical ("Failed to get sender: %s", strerror(-res));
            comm_data = "_COMM=kernel".data;
        }

        var origin = ((string) comm_data).offset ("_COMM=".length);
        var message = ((string) data).offset("MESSAGE=".length);

        var entry = new SystemdLogEntry (origin, message);

        if (current_search_term.strip () != "" && !entry.matches (current_search_term)) {
            return true;
        }

        entries.add (entry);

        items_changed (entries.size - 1, 0, 1);

        return true;
    }

    public void search (string term) {
        reset ();
        current_search_term = term;
        init ();
    }

    public void refresh () {
        reset ();
        current_tail = 0;
        init ();
    }

    public Object? get_item (uint position) {
        if (position >= entries.size) {
            return null;
        } else {
            return entries[(int) position];
        }
    }

    public Type get_item_type () {
        return typeof(SystemdLogEntry);
    }

    public uint get_n_items () {
        return entries.size;
    }
}
