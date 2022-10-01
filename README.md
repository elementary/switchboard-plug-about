# Switchboard System Plug
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-about/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libswitchboard-2.0-dev
* libfwupd-dev
* libgranite-dev
* libgtk-3-dev
* libgtop2-dev
* libgudev-1.0-dev
* libhandy-1-dev
* libappstream-dev
* meson
* valac
* switcheroo-control (at runtime)

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install

## OEM Configuration

The Switchboard System plug can load OEM information supplied by an `oem.conf` file placed in `/etc` with the following format:

```ini
[OEM]
# Human-facing OEM name
Manufacturer=Star Labs

# Device name
Product=StarBook

# Human-facing model number or version, expected to be slightly de-emphasized
Version=Mk V

# Path to a logo or hardware image, expected to be shown on a light background
Logo=/etc/oem/logo.png

# Optional version of the above image expected to be shown on a dark background
# LogoDark=/etc/oem/logo-dark.png

# OEM URL, e.g. for information and/or end user support
URL=https://support.starlabs.systems/
```
