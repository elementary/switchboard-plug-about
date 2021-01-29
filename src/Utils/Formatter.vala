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
}
