# Description ##

I too was tired of having to configure manually the disposition of my monitors when I plugged them in.

So I decided to google for "Monitor hotplugging linux" and found this script that defines custom behaviour when monitor are plugged in.

I have adapted the original script to use loginctl, I'm sure this can be improved, and have set the monitors to --preferred for resolution rather than statically setting a resolution.

Added functionality for Display Link devices which show up, under the latest modesetting driver, as DVI-1-X. On my local machine ~~I have patched modesetting to only name the device DVI-1-0 as this makes things easier in i3wm with workspace assignments~~ I have modified this version again to support the latest modesetting driver without any patches, the device name will now be grabbed from xrandr and set accordingly for i3-wm users, this will also automatically move workspaces of your choice to that new screen and back again.

All files should be reviewed and addapted to your specific configuration.

I was inspired by the original author to adapt this script to my own needs.

The original author was inspired by http://stackoverflow.com/questions/5469828/how-to-create-a-callback-for-monitor-plugged-on-an-intel-graphics

## Installation ##
  * clone the repo
  * move or copy hotplug.sh somewhere special to you
  * move or copy 99-monitor-hotplug.rules to /etc/udev/rules.d/
  * edit 99-monitor-hotplug.rules and replace RUN+="..." with the path to hotplug.sh
  * consider rebooting or running `udevadm trigger` to load the rule
  * copy the optional resume@ and suspend@ service files and enable them for your primary user

## Debuging ##
  * `udevadm monitor --property` to see what happens when you plug or unplug a monitor

## License ##

I'm not responsible of the effect of this script on your computer

Feel free to do whatever you want with it :-)

## Changelog ##


### 0.0.1 ###
Latest adjustments, code cleanup, added dynamic pluggability to a *single* Display Link device.
Accidental unplug should still recover workspaces in i3-wm.
Added suspend@ and resume@ systemd service files for auto-disconnect and auto-reconnect on suspend and resume.

### 0.0.0 ###
Original fork and adjustment to my needs
