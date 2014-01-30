#!/bin/bash
# TODO: clean up code where possible
# TODO: convert to switch statement for enabling the screens
# TODO: resolve i3wm crash on hotplug, likely due to XAUTHORITY


#Adapt this script to your needs.

DEVICES=$(find /sys/class/drm/*/status)

#inspired by /etc/acpd/lid.sh and the function it sources

DISPLAYNUM=$(ls /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##)
export DISPLAY=":$DISPLAYNUM"

if [[ $(loginctl list-sessions | grep -q seat0) -eq 0 ]]; then
	# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
	export XAUTHORITY=$(ps -C X -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')
else
	echo "unable to find an X session"
	exit 1
fi

#this while loop declare the $HDMI1 $VGA1 $LVDS1 $DISPLAYLINK and others if they are plugged in
while read l
do
	DIR=$(dirname $l);
	STATUS=$(cat $l);
	DEV=$(echo "$DIR" | cut -d\- -f 2-);

	if [[ $(expr match "$DEV" "HDMI") != "0" ]]
	then
		#REMOVE THE -X- part from HDMI-X-n
		DEV=HDMI"${DEV#HDMI-?-}"
	elif [[ $(expr match "$DEV" "DVI") != "0" ]]
	then
		#REMOVE THE -X- part from DVI-X-n
		DEV="DISPLAYLINK"
	else
		DEV=$(echo "$DEV" | tr -d '-')
	fi

	if [[ "connected" == "$STATUS" ]]
	then
		echo "$DEV "is connected""
		declare "$DEV="yes""
	fi
done <<< "$DEVICES"
if [[ -n "$HDMI1" ]] && [[ -n "$VGA1" ]] && [[ -n "$DISPLAYLINK" ]]
then
	echo "HDMI1, VGA1, and DISPLAYLINK are plugged in"
	# enable displaylink device and special resolution for ThinkVision display
	xrandr --setprovideroutputsource 1 0
	xrandr --newmode "1368x768_59.99"  85.85  1368 1440 1584 1800  768 769 772 795  -HSync +Vsync
	xrandr --addmode DVI-1-0 1368x768_59.99

	#turn on them screens
	xrandr --output DVI-1-0 --mode 1368x768_59.99 --right-of LVDS1 --rotate normal \
	--output VGA1 --preferred --left-of LVDS1 --rotate normal \
	--output HDMI1 --preferred --below LVDS1 --rotate normal
elif [[ -n "$HDMI1" ]] && [[ -n "$DISPLAYLINK" ]]
then
	echo "HDMI1 and DISPLAYLINK are plugged in"
	# enable displaylink device and special resolution for ThinkVision display
	xrandr --setprovideroutputsource 1 0
	xrandr --newmode "1368x768_59.99"  85.85  1368 1440 1584 1800  768 769 772 795  -HSync +Vsync
	xrandr --addmode DVI-1-0 1368x768_59.99

	#turn on them screens
	xrandr --output DVI-1-0 --mode 1368x768_59.99 --right-of LVDS1 --rotate normal \
	--output HDMI1 --preferred --below LVDS1 --rotate normal
elif [[ -n "$VGA1" ]] && [[ -n "$DISPLAYLINK" ]]
then
	echo "VGA1 and DISPLAYLINK are plugged in"
	# enable displaylink device and special resolution for ThinkVision display
	xrandr --setprovideroutputsource 1 0
	xrandr --newmode "1368x768_59.99"  85.85  1368 1440 1584 1800  768 769 772 795  -HSync +Vsync
	xrandr --addmode DVI-1-0 1368x768_59.99

	#turn on them screens
	xrandr --output DVI-1-0 --mode 1368x768_59.99 --right-of LVDS1 --rotate normal \
	--output VGA1 --preferred --left-of LVDS1 --rotate normal
elif [[ -n "$DISPLAYLINK" ]]
then
	echo "DISPLAYLINK is plugged in"
	# enable displaylink device and special resolution for ThinkVision display
	xrandr --setprovideroutputsource 1 0
	xrandr --newmode "1368x768_59.99"  85.85  1368 1440 1584 1800  768 769 772 795  -HSync +Vsync
	xrandr --addmode DVI-1-0 1368x768_59.99

	#turn on that screen
	xrandr --output DVI-1-0 --mode 1368x768_59.99 --right-of LVDS1 --rotate normal
elif [[ -n "$HDMI1" ]] && [[ -n "$VGA1" ]]
then
	echo "HDMI1 and VGA1 are plugged in"

	xrandr --output VGA1 --auto --right-of LVDS1
	xrandr --output HDMI1 --auto --right-of VGA1
elif [[ -n "$HDMI1" ]] && [[ -z "$VGA1" ]];
then
	echo "HDMI1 is plugged in, VGA1 and Display Link are unplugged"

	xrandr --output VGA1 --off
	xrandr --output HDMI1 --auto --right-of LVDS1
elif [[ -z "$HDMI1" ]] && [[ -n "$VGA1" ]];
then
	echo "VGA1 is plugged in, HDMI1 and Display Link are unplugged"

	xrandr --output HDMI1 --off
	xrandr --output VGA1 --auto --right-of LVDS1
else
	echo "No external monitors are plugged in"

	xrandr --output DVI-1-0 --off
	xrandr --output HDMI1 --off
	xrandr --output VGA1 --off
fi
