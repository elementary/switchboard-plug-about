/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class About.SystemdLogRow : GLib.Object {
    public string origin { get; construct; }
    public string message { get; construct; }

    public SystemdLogRow (string origin, string message) {
        Object(origin: origin, message: message);
    }
}

public class About.SystemdLogModel : GLib.Object, GLib.ListModel {
    private GLib.HashTable<uint, unowned About.SystemdLogRow> cached_rows;
    private uint current_line = uint.MAX;
    private uint num_entries = 0;
    private Systemd.Journal journal;

    construct {
        cached_rows = new GLib.HashTable<uint, unowned About.SystemdLogRow>(GLib.direct_hash, GLib.direct_equal);
        create_journal ();
        load_data.begin ();
    }

    private void create_journal () {
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

        journal.add_match ("_BOOT_ID=%s".printf(boot_id.str).data);
        journal.add_conjunction ();
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
                current_line += num_entries;
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
            uint added = 0, old_num_entries = 0;
            lock (journal) {
                old_num_entries = num_entries;
                added = load_next_entries ();
            }
            if (added > 0) {
                items_changed (old_num_entries, 0, added);
                return Source.CONTINUE;
            } else {
                return Source.REMOVE;
            }
        }, GLib.Priority.LOW);
    }

    public Object? get_item (uint position) {
        About.SystemdLogRow? row = null;
        lock (journal) {
            row = cached_rows.get (position);
            if (row != null) {
                return row;
            }

            int res = journal.seek_head ();
            current_line = 0;
            if (res != 0) {
                critical ("%s", strerror(-res));
                return null;
            }

            res = journal.next ();
            if (res < 0) {
                critical ("%s", strerror(-res));
                return null;
            }

            res = journal.next_skip (position);
            current_line += position;
            if (res < 0) {
                critical ("%s", strerror(-res));
                return null;
            }

            unowned uint8[] data;
            unowned uint8[] comm_data;
            res = journal.get_data ("MESSAGE", out data);
            if (res != 0) {
                critical ("%s", strerror(-res));
                return null;
            }

            res = journal.get_data ("_COMM", out comm_data);
            if (res != 0) {
                //critical ("%s %s", strerror(-res), (string) data);
                comm_data = "_COMM=kernel".data;
            }

            row = new About.SystemdLogRow (((string)comm_data).offset ("_COMM=".length), ((string)data).offset("MESSAGE=".length));
            cached_rows.set (position, row);
            row.weak_ref((obj) => {
                cached_rows.foreach_remove ((key, val) => {
                    return val == obj;
                });
            });
        }

        return (owned)row;
    }

    public Type get_item_type () {
        return typeof(About.SystemdLogRow);
    }

    public uint get_n_items () {
        return num_entries;
    }
}
