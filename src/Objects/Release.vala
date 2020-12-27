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

public class About.Release : Object {
    public string filename { get; set; }
    public string name { get; set; }
    public string summary { get; set; }
    public string icon { get; set; }
    public string version { get; set; }
    public string description { get; set; }
    public string protocol { get; set; }
    public string remote_id { get; set; }
    public string appstream_id { get; set; }
    public string checksum { get; set; }
    public string vendor { get; set; }
    public uint64 size { get; set; }
    public string license { get; set; }
    public ReleaseFlag flag { get; set; }
    public uint32 install_duration { get; set; }
    public string uri { get; set; }
}
