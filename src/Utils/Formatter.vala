/*
 * Copyright (c) 2021 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class About.Formatter {
    public static string bytes_to_string (uint64 bytes) {
        if (bytes > 1000000000) {
            return "%.1f GB".printf (bytes / 1000000000.0);
        } else if (bytes > 1000000) {
            return "%.1f MB".printf (bytes / 1000000.0);
        } else if (bytes > 1000) {
            return "%.1f kB".printf (bytes / 1000.0);
        }

        return "%llu B".printf (bytes);
    }

    public static string? seconds_to_string (uint64 seconds) {
        uint64 minutes, hours;

        if (seconds == 0) {
            return null;
        }

        if (seconds >= 60) {
            minutes = seconds / 60;
            seconds = seconds % 60;

            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
                return _("%llu hr, %llu min, %llu sec").printf (hours, minutes, seconds);
            }

            return _("%llu min, %llu sec").printf (minutes, seconds);
        }

        return _("%llu sec").printf (seconds);
    }

    public static string xml_to_string (string markup) {
        string result = markup;

        var open_tag = "<ul>";
        var close_tag = "</ul>";
        while (result.contains (open_tag)) {
            var start = result.index_of (open_tag);
            var end = result.index_of (close_tag);

            var head = result.substring (0, start);
            var body = result.substring (start + open_tag.length, end - start - open_tag.length - close_tag.length)
                .replace ("<li>", " • ").replace ("</li>", "\n") + "\n\n";
            var tail = result.substring (end + close_tag.length, result.length - end - close_tag.length);
            result = head + body + tail;
        }

        open_tag = "<ol>";
        close_tag = "</ol>";
        while (result.contains (open_tag)) {
            int i = 1;
            var start = result.index_of (open_tag);
            var end = result.index_of (close_tag);

            var head = result.substring (0, start);
            var body = result.substring (start + open_tag.length, end - start - open_tag.length - close_tag.length)
                .replace ("<li>", " %u. ".printf (i++)).replace ("</li>", "\n") + "\n\n";
            var tail = result.substring (end + close_tag.length, result.length - end - close_tag.length);
            result = head + body + tail;
        }

        result = result
            .replace ("<p>", "")
            .replace ("</p>", "\n\n");

        return result.strip ();
    }
}
