/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.SystemdLogEntry : GLib.Object {
    public unowned SystemdLogModel model { get; construct; }
    public int pos { get; construct; }

    public string origin { get; private set; default = ""; }
    public string message { get; private set; default = ""; }

    private bool loaded = false;

    public SystemdLogEntry (SystemdLogModel model, int pos) {
        Object (model: model, pos: pos);
    }

    public void queue_load () {
        if (loaded) {
            return;
        }
        loaded = true;

        Idle.add (load, GLib.Priority.LOW);
    }

    private bool load () {
        model.goto (pos);

        unowned uint8[] data;
        unowned uint8[] comm_data;
        int res = model.journal.get_data ("MESSAGE", out data);
        if (res != 0) {
            critical ("%s", strerror(-res));
            return Source.REMOVE;
        }

        res = model.journal.get_data ("_COMM", out comm_data);
        if (res != 0) {
            critical ("%s %s", strerror(-res), (string) comm_data);
            comm_data = "_COMM=kernel".data;
        }

        origin = ((string) comm_data).offset ("_COMM=".length);
        message = ((string) data).offset("MESSAGE=".length);

        return Source.REMOVE;
    }
}

public class About.SystemdLogModel : GLib.Object, GLib.ListModel {
    private const int CHUNK = 2000;

    private Systemd.Journal _journal;
    public Systemd.Journal journal { get { return _journal; } }

    private GLib.HashTable<uint, SystemdLogEntry> cached_entries;
    private int current_line = int.MAX;
    private uint num_entries = 0;

    construct {
        cached_entries = new GLib.HashTable<uint, SystemdLogEntry>(GLib.direct_hash, GLib.direct_equal);

        int res = Systemd.Journal.open_namespace (out _journal, null, LOCAL_ONLY);
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

        journal.add_match ("_BOOT_ID=%s".printf(boot_id.str).data);
        journal.add_conjunction ();
        journal.seek_tail ();
        journal.previous ();
        current_line = 0;

        load_data.begin ();
    }

    public void goto (int pos) {
        if (current_line == pos) {
            return;
        }

        var diff = current_line - pos;

        int res;
        if (diff < 0) {
            res = journal.previous_skip (-diff);
        } else {
            res = journal.next_skip (diff);
        }

        if (res < 0) {
            critical ("Failed to go to pos %d: %s", pos, strerror(-res));
            return;
        }

        current_line = pos;
    }

    private void load_chunk () {
        int to_load = CHUNK;
        Idle.add (() => {
            load_next_entry ();
            to_load--;
            return (to_load > 0 ? Source.CONTINUE : Source.REMOVE);
        }, GLib.Priority.LOW);
    }

    private void load_next_entry () {
        num_entries++;
        items_changed (num_entries - 1, 0, 1);
    }

    private uint load_next_entries () {
        if (current_line != num_entries) {
            int res = journal.seek_head ();
            current_line = 0;
            if (res != 0) {
                critical ("%s", strerror(-res));
                return 0;
            }

            if (num_entries > 0) {
                res = journal.next_skip (num_entries);
                //  current_line += num_entries;
                if (res < 0) {
                    critical ("%s", strerror(-res));
                    return 0;
                }
            }
        }

        int res = journal.next ();
        if (res < 0) {
            critical ("%s", strerror(-res));
            return 0;
        }

        current_line += res;
        num_entries += res;
        return res;
    }

    private async void load_data () {
        GLib.Idle.add(() => {
            load_chunk ();
            return Source.REMOVE;
            //  uint added = 0, old_num_entries = 0;
            //  lock (journal) {
            //      old_num_entries = num_entries;
            //      added = load_next_entries ();
            //  }
            //  if (added > 0) {
            //      items_changed (old_num_entries, 0, added);
            //      return Source.CONTINUE;
            //  } else {
            //      return Source.REMOVE;
            //  }
        }, GLib.Priority.LOW);
    }

    public Object? get_item (uint position) {
        SystemdLogEntry? entry = null;
        entry = cached_entries.get (position);
        if (entry != null) {
            return entry;
        }

        entry = new SystemdLogEntry (this, (int) position);
        cached_entries[position] = entry;
        return entry;
    }

    public Type get_item_type () {
        return typeof(SystemdLogEntry);
    }

    public uint get_n_items () {
        return num_entries;
    }
}
