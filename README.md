# Description

I too was tired of having to configure manually the disposition of my monitors when I plugged them in.

So I decided to google for "Monitor hotplugging linux" and found this script that defines custom behaviour when monitor are plugged in. I have adapted the original script to use loginctl, I'm sure this can be improved, and have set the monitors to --auto for resolution rather than statically setting one.

You might want to adapt the script to your needs, hotplug.sh

The original author was inspired by http://stackoverflow.com/questions/5469828/how-to-create-a-callback-for-monitor-plugged-on-an-intel-graphics

## Installation
  * clone the repo
  * move or copy hotplug.sh into your local $PATH
  * move or copy 99-monitor-hotplug.rules to /etc/udev/rules.d/
  * consider rebooting or running `udevadm trigger` to load the rule

## Debuging
  * `udevadm monitor --property` to see what happens when you plug or unplug a monitor


## License

I'm not responsible of the effect of this script on your computer

Feel free to do whatever you want with it :-)
