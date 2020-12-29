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

// https://github.com/fwupd/fwupd/blob/72df1147933de747312aa7c9892f07e7916b8a39/libfwupd/fwupd-enums.h#L133
public enum About.DeviceFlag {
    NONE = (0u),                         /* Since: 0.1.3 */
    INTERNAL = (1u << 0),                /* Since: 0.1.3 */
    UPDATABLE = (1u << 1),               /* Since: 0.9.7 */
    ONLY_OFFLINE = (1u << 2),            /* Since: 0.9.7 */
    REQUIRE_AC = (1u << 3),              /* Since: 0.6.3 */
    LOCKED = (1u << 4),                  /* Since: 0.6.3 */
    SUPPORTED = (1u << 5),               /* Since: 0.7.1 */
    NEEDS_BOOTLOADER = (1u << 6),        /* Since: 0.7.3 */
    REGISTERED = (1u << 7),              /* Since: 0.9.7 */
    NEEDS_REBOOT = (1u << 8),            /* Since: 0.9.7 */
    REPORTED = (1u << 9),                /* Since: 1.0.4 */
    NOTIFIED = (1u << 10),               /* Since: 1.0.5 */
    USE_RUNTIME_VERSION = (1u << 11),    /* Since: 1.0.6 */
    INSTALL_PARENT_FIRST = (1u << 12),   /* Since: 1.0.8 */
    IS_BOOTLOADER= (1u << 13),           /* Since: 1.0.8 */
    WAIT_FOR_REPLUG = (1u << 14),        /* Since: 1.1.2 */
    IGNORE_VALIDATION = (1u << 15),      /* Since: 1.1.2 */
    TRUSTED = (1u << 16),                /* Since: 1.1.2 */
    NEEDS_SHUTDOWN = (1u << 17),         /* Since: 1.2.4 */
    ANOTHER_WRITE_REQUIRED = (1u << 18), /* Since: 1.2.5 */
    NO_AUTO_INSTANCE_IDS = (1u << 19),   /* Since: 1.2.5 */
    NEEDS_ACTIVATION = (1u << 20),       /* Since: 1.2.6 */
    ENSURE_SEMVER= (1u << 21),           /* Since: 1.2.9 */
    HISTORICAL = (1u << 22),             /* Since: 1.3.2 */
    ONLY_SUPPORTED = (1u << 23),         /* Since: 1.3.3 */
    WILL_DISAPPEAR = (1u << 24),         /* Since: 1.3.3 */
    CAN_VERIFY = (1u << 25),             /* Since: 1.3.3 */
    CAN_VERIFY_IMAGE = (1u << 26),       /* Since: 1.3.3 */
    DUAL_IMAGE = (1u << 27),             /* Since: 1.3.3 */
    SELF_RECOVERY= (1u << 28),           /* Since: 1.3.3 */
    USABLE_DURING_UPDATE = (1u << 29),   /* Since: 1.3.3 */
    VERSION_CHECK_REQUIRED = (1u << 30), /* Since: 1.3.7 */
    INSTALL_ALL_RELEASES = (1u << 31),   /* Since: 1.3.7 */
    MD_SET_NAME= (1u << 32),             /* Since: 1.4.0 */
    MD_SET_NAME_CATEGORY = (1u << 33),   /* Since: 1.4.0 */
    MD_SET_VERFMT= (1u << 34),           /* Since: 1.4.0 */
    ADD_COUNTERPART_GUIDS= (1u << 35),   /* Since: 1.4.0 */
    NO_GUID_MATCHING = (1u << 36),       /* Since: 1.4.1 */
    UPDATABLE_HIDDEN = (1u << 37),       /* Since: 1.4.1 */
    SKIPS_RESTART= (1u << 38),           /* Since: 1.5.0 */
    HAS_MULTIPLE_BRANCHES = (1u << 39),  /* Since: 1.5.0 */
    BACKUP_BEFORE_INSTALL = (1u << 40),  /* Since: 1.5.0 */
    MD_SET_ICON = (1u << 41),            /* Since: 1.5.2 */
    UNKNOWN = uint64.MAX;                /* Since: 0.7.3 */

    public static List<DeviceFlag> get_list (uint64 flags) {
        var list = new List<DeviceFlag> ();

        if ((flags & (0u)) > 0) {
            list.append (DeviceFlag.NONE);
        }
        if ((flags & (1u << 0)) > 0) {
            list.append (DeviceFlag.INTERNAL);
        }
        if ((flags & (1u << 1)) > 0) {
            list.append (DeviceFlag.UPDATABLE);
        }
        if ((flags & (1u << 2)) > 0) {
            list.append (DeviceFlag.ONLY_OFFLINE);
        }
        if ((flags & (1u << 3)) > 0) {
            list.append (DeviceFlag.REQUIRE_AC);
        }
        if ((flags & (1u << 4)) > 0) {
            list.append (DeviceFlag.LOCKED);
        }
        if ((flags & (1u << 5)) > 0) {
            list.append (DeviceFlag.SUPPORTED);
        }
        if ((flags & (1u << 6)) > 0) {
            list.append (DeviceFlag.NEEDS_BOOTLOADER);
        }
        if ((flags & (1u << 7)) > 0) {
            list.append (DeviceFlag.REGISTERED);
        }
        if ((flags & (1u << 8)) > 0) {
            list.append (DeviceFlag.NEEDS_REBOOT);
        }
        if ((flags & (1u << 9)) > 0) {
            list.append (DeviceFlag.REPORTED);
        }
        if ((flags & (1u << 10)) > 0) {
            list.append (DeviceFlag.NOTIFIED);
        }
        if ((flags & (1u << 11)) > 0) {
            list.append (DeviceFlag.USE_RUNTIME_VERSION);
        }
        if ((flags & (1u << 12)) > 0) {
            list.append (DeviceFlag.INSTALL_PARENT_FIRST);
        }
        if ((flags & (1u << 13)) > 0) {
            list.append (DeviceFlag.IS_BOOTLOADER);
        }
        if ((flags & (1u << 14)) > 0) {
            list.append (DeviceFlag.WAIT_FOR_REPLUG);
        }
        if ((flags & (1u << 15)) > 0) {
            list.append (DeviceFlag.IGNORE_VALIDATION);
        }
        if ((flags & (1u << 16)) > 0) {
            list.append (DeviceFlag.TRUSTED);
        }
        if ((flags & (1u << 17)) > 0) {
            list.append (DeviceFlag.NEEDS_SHUTDOWN);
        }
        if ((flags & (1u << 18)) > 0) {
            list.append (DeviceFlag.ANOTHER_WRITE_REQUIRED);
        }
        if ((flags & (1u << 19)) > 0) {
            list.append (DeviceFlag.NO_AUTO_INSTANCE_IDS);
        }
        if ((flags & (1u << 20)) > 0) {
            list.append (DeviceFlag.NEEDS_ACTIVATION);
        }
        if ((flags & (1u << 21)) > 0) {
            list.append (DeviceFlag.ENSURE_SEMVER);
        }
        if ((flags & (1u << 22)) > 0) {
            list.append (DeviceFlag.HISTORICAL);
        }
        if ((flags & (1u << 23)) > 0) {
            list.append (DeviceFlag.ONLY_SUPPORTED);
        }
        if ((flags & (1u << 24)) > 0) {
            list.append (DeviceFlag.WILL_DISAPPEAR);
        }
        if ((flags & (1u << 25)) > 0) {
            list.append (DeviceFlag.CAN_VERIFY);
        }
        if ((flags & (1u << 26)) > 0) {
            list.append (DeviceFlag.CAN_VERIFY_IMAGE);
        }
        if ((flags & (1u << 27)) > 0) {
            list.append (DeviceFlag.DUAL_IMAGE);
        }
        if ((flags & (1u << 28)) > 0) {
            list.append (DeviceFlag.SELF_RECOVERY);
        }
        if ((flags & (1u << 29)) > 0) {
            list.append (DeviceFlag.USABLE_DURING_UPDATE);
        }
        if ((flags & (1u << 30)) > 0) {
            list.append (DeviceFlag.VERSION_CHECK_REQUIRED);
        }
        if ((flags & (1u << 31)) > 0) {
            list.append (DeviceFlag.INSTALL_ALL_RELEASES);
        }
        if ((flags & (1u << 32)) > 0) {
            list.append (DeviceFlag.MD_SET_NAME);
        }
        if ((flags & (1u << 33)) > 0) {
            list.append (DeviceFlag.MD_SET_NAME_CATEGORY);
        }
        if ((flags & (1u << 34)) > 0) {
            list.append (DeviceFlag.MD_SET_VERFMT);
        }
        if ((flags & (1u << 35)) > 0) {
            list.append (DeviceFlag.ADD_COUNTERPART_GUIDS);
        }
        if ((flags & (1u << 36)) > 0) {
            list.append (DeviceFlag.NO_GUID_MATCHING);
        }
        if ((flags & (1u << 37)) > 0) {
            list.append (DeviceFlag.UPDATABLE_HIDDEN);
        }
        if ((flags & (1u << 38)) > 0) {
            list.append (DeviceFlag.SKIPS_RESTART);
        }
        if ((flags & (1u << 39)) > 0) {
            list.append (DeviceFlag.HAS_MULTIPLE_BRANCHES);
        }
        if ((flags & (1u << 40)) > 0) {
            list.append (DeviceFlag.BACKUP_BEFORE_INSTALL);
        }
        if ((flags & (1u << 41)) > 0) {
            list.append (DeviceFlag.MD_SET_ICON);
        }
        if ((flags & (uint64.MAX)) > 0) {
            list.append (DeviceFlag.UNKNOWN);
        }

        return list;
    }

    // https://gitlab.gnome.org/hughsie/gnome-firmware-updater/-/blob/f5281078e3cfade7ff919c812ba63de22431aaf2/src/gfu-common.c#L249
    public string? to_string () {
        switch (this) {
            case NONE:
                return null;
            case INTERNAL:
                /* TRANSLATORS: Device cannot be removed easily*/
                return _("Internal device");
            case UPDATABLE:
                /* TRANSLATORS: Device is updatable in this or any other mode */
                return _("Updatable");
            case ONLY_OFFLINE:
                /* TRANSLATORS: Update can only be done from offline mode */
                return _("Update requires a reboot");
            case REQUIRE_AC:
                /* TRANSLATORS: Must be plugged in to an outlet */
                return _("System requires external power source");
            case LOCKED:
                /* TRANSLATORS: Is locked and can be unlocked */
                return _("Device is locked");
            case SUPPORTED:
                /* TRANSLATORS: Is found in current metadata */
                return _("Supported on LVFS");
            case NEEDS_BOOTLOADER:
                /* TRANSLATORS: Requires a bootloader mode to be manually enabled by the user */
                return _("Requires a bootloader");
            case NEEDS_REBOOT:
                /* TRANSLATORS: Requires a reboot to apply firmware or to reload hardware */
                return _("Needs a reboot after installation");
            case NEEDS_SHUTDOWN:
                /* TRANSLATORS: Requires system shutdown to apply firmware */
                return _("Needs shutdown after installation");
            case REPORTED:
                /* TRANSLATORS: Has been reported to a metadata server */
                return _("Reported to LVFS");
            case NOTIFIED:
                /* TRANSLATORS: User has been notified */
                return _("User has been notified");
            case USE_RUNTIME_VERSION:
                /* skip */
                return null;
            case INSTALL_PARENT_FIRST:
                /* TRANSLATORS: Install composite firmware on the parent before the child */
                return _("Install to parent device first");
            case IS_BOOTLOADER:
                /* TRANSLATORS: Is currently in bootloader mode */
                return _("Is in bootloader mode");
            case WAIT_FOR_REPLUG:
                /* TRANSLATORS: The hardware is waiting to be replugged */
                return _("Hardware is waiting to be replugged");
            case IGNORE_VALIDATION:
                /* TRANSLATORS: Ignore validation safety checks when flashing this device */
                return _("Ignore validation safety checks");
            case ANOTHER_WRITE_REQUIRED:
                /* skip */
                return null;
            case NO_AUTO_INSTANCE_IDS:
                /* skip */
                return null;
            case NEEDS_ACTIVATION:
                /* TRANSLATORS: Device update needs to be separately activated */
                return _("Device update needs activation");
            case ENSURE_SEMVER:
                /* skip */
                return null;
            case HISTORICAL:
                /* skip */
                return null;
            case ONLY_SUPPORTED:
                /* skip */
                return null;
            case WILL_DISAPPEAR:
                /* TRANSLATORS: Device will not return after update completes */
                return _("Device will not re-appear after update completes");
            case CAN_VERIFY:
                /* TRANSLATORS: Device supports some form of checksum verification */
                return _("Cryptographic hash verification is available");
            case CAN_VERIFY_IMAGE:
                /* skip */
                return null;
            case DUAL_IMAGE:
                /* TRANSLATORS: Device supports a safety mechanism for flashing */
                return _("Device stages updates");
            case SELF_RECOVERY:
                /* TRANSLATORS: Device supports a safety mechanism for flashing */
                return _("Device can recover flash failures");
            case USABLE_DURING_UPDATE:
                /* TRANSLATORS: Device remains usable during update */
                return _("Device is usable for the duration of the update");
            case UNKNOWN:
                return null;
            default:
                return null;
        }
    }

    // https://gitlab.gnome.org/hughsie/gnome-firmware-updater/-/blob/f5281078e3cfade7ff919c812ba63de22431aaf2/src/gfu-common.c#L377
    public string to_icon () {
        switch (this) {
            case INTERNAL:
                return "drive-harddisk-symbolic";
            case UPDATABLE:
                return "software-update-available-symbolic";
            case ONLY_OFFLINE:
                return "network-offline-symbolic";
            case REQUIRE_AC:
                return "battery-symbolic";
            case LOCKED:
                return "locked-symbolic";
            case SUPPORTED:
                return "security-high-symbolic";
            case NEEDS_BOOTLOADER:
                return "computer-symbolic";
            case NEEDS_REBOOT:
                return "system-reboot-symbolic";
            case NEEDS_SHUTDOWN:
                return "system-shutdown-symbolic";
            case REPORTED:
                return "task-due-symbolic";
            case NOTIFIED:
                return "task-due-symbolic";
            case USE_RUNTIME_VERSION:
                return "system-run-symbolic";
            case INSTALL_PARENT_FIRST:
                return "system-software-install-symbolic";
            case IS_BOOTLOADER:
                return "computer-symbolic";
            case WAIT_FOR_REPLUG:
                return "battery-low-symbolic";
            case IGNORE_VALIDATION:
                return "dialog-error-symbolic";
            case ANOTHER_WRITE_REQUIRED:
                return "media-floppy-symbolic";
            case NO_AUTO_INSTANCE_IDS:
                return "dialog-error-symbolic";
            case NEEDS_ACTIVATION:
                return "emblem-important-symbolic";
            case ENSURE_SEMVER:
                return "emblem-important-symbolic";
            case WILL_DISAPPEAR:
                return "emblem-important-symbolic";
            case CAN_VERIFY:
                return "emblem-important-symbolic";
            case DUAL_IMAGE:
                return "emblem-important-symbolic";
            case SELF_RECOVERY:
                return "emblem-important-symbolic";
            case USABLE_DURING_UPDATE:
                return "emblem-important-symbolic";
            case UNKNOWN:
                return "unknown-symbolic";
            default:
                return "unknown-symbolic";
        }
    }
}
