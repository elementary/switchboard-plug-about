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

public class Fwupd.Device : Object {
    public string id { get; set; }
    public string name { get; set; }
    public string summary { get; set; }
    public string icon { get; set; }
    public string vendor { get; set; }
    public string version { get; set; }
    public string[] guids { get; set; }
    public DeviceFlag flags { get; set; }
    public uint32 install_duration { get; set; }
    public string update_error { get; set; }

    public List<Release> releases { get; owned set; }
    public Release latest_release { get { return releases.nth_data (0); }}

    public bool has_flag (Fwupd.DeviceFlag flag) {
        return flag in flags;
    }

    public bool is_updatable { get { return releases.length () > 0 && latest_release.version != version; }}
}
