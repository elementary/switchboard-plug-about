/*
* Copyright (c) 2020 elementary, Inc. (https://elementary.io)
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

// https://github.com/fwupd/fwupd/blob/72df1147933de747312aa7c9892f07e7916b8a39/libfwupd/fwupd-enums.h#L192
[Flags]
public enum About.Firmware.ReleaseFlag {
    NONE = (0u),                     /* Since: 1.2.6 */
    TRUSTED_PAYLOAD = (1u << 0),     /* Since: 1.2.6 */
    TRUSTED_METADATA = (1u << 1),    /* Since: 1.2.6 */
    IS_UPGRADE = (1u << 2),          /* Since: 1.2.6 */
    IS_DOWNGRADE = (1u << 3),        /* Since: 1.2.6 */
    BLOCKED_VERSION = (1u << 4),     /* Since: 1.2.6 */
    BLOCKED_APPROVAL = (1u << 5),    /* Since: 1.2.6 */
    IS_ALTERNATE_BRANCH = (1u << 6), /* Since: 1.5.0 */
    UNKNOWN = uint64.MAX;            /* Since: 1.2.6 */
}
