# Description

I too was tired of having to configure manually the disposition of my monitors when I plugged them in.

So I decided to google for "Monitor hotplugging linux" and found this script that defines custom behaviour when monitor are plugged in.

I have adapted the original script to use loginctl, I'm sure this can be improved, and have set the monitors to --preferred for resolution rather than statically setting one.

Added functionality for Display Link devices which show up, under the latest modesetting driver, as DVI-1-X. On my local machine I have patched modesetting to only name the device DVI-1-0 as this makes things easier in i3wm with workspace assignments.

You might want to adapt the script to your needs, hotplug.sh

The original author was inspired by http://stackoverflow.com/questions/5469828/how-to-create-a-callback-for-monitor-plugged-on-an-intel-graphics

## Installation
  * clone the repo
  * move or copy hotplug.sh somewhere special to you
  * move or copy 99-monitor-hotplug.rules to /etc/udev/rules.d/
  * edit 99-monitor-hotplug.rules and replace "$PATH_TO_SCRIPT" with your special location for hotplug.sh ( I use "/home/gehidore/.local/pbin/udev-monitor-hotplug/hotplug.sh"
  * consider rebooting or running `udevadm trigger` to load the rule

## Debuging
  * `udevadm monitor --property` to see what happens when you plug or unplug a monitor


## License

I'm not responsible of the effect of this script on your computer

Feel free to do whatever you want with it :-)
