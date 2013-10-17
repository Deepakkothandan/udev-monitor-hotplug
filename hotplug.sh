#!/bin/bash

#Adapt this script to your needs.

DEVICES=$(find /sys/class/drm/*/status)

#inspired by /etc/acpd/lid.sh and the function it sources

DISPLAYNUM=`ls /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##`
export DISPLAY=":$DISPLAYNUM"

if [[ $(loginctl list-sessions | grep -q seat0) -eq 0 ]]; then
	# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
	export XAUTHORITY=$(ps -C Xorg -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')
else
	echo "unable to find an X session"
	exit 1
fi

#this while loop declare the $HDMI1 $VGA1 $LVDS1 and others if they are plugged in
while read l
do
	DIR=$(dirname $l);
	STATUS=$(cat $l);
	DEV=$(echo "$DIR" | cut -d\- -f 2-);

	if [[ $(expr match "$DEV" "HDMI") != "0" ]]
	then
		#REMOVE THE -X- part from HDMI-X-n
		DIR=HDMI"${DEV#HDMI-?-}"
	else
		DEV=$(echo "$DEV" | tr -d '-')
	fi

	if [[ "connected" == "$STATUS" ]]
	then
		echo "$DEV "connected""
		declare $DEV="yes"
	fi
done <<< "$DEVICES"

if [[ -n "$HDMI1" ]] && [[ -n "$VGA1" ]]
then
	echo "HDMI1 and VGA1 are plugged in"
	#  xrandr --output LVDS1 --off
	xrandr --output VGA1 --auto --right-of LVDS1
	xrandr --output HDMI1 --auto --right-of VGA1
elif [[ -n "$HDMI1" ]] && [[ -z "$VGA1" ]];
then
	echo "HDMI1 is plugged in, but not VGA1"
	#  xrandr --output LVDS1 --off
	xrandr --output VGA1 --off
	xrandr --output HDMI1 --auto --right-of LVDS1
elif [[ -z "$HDMI1" ]] && [[ -n "$VGA1" ]];
then
	echo "VGA1 is plugged in, but not HDMI1"
	#  xrandr --output LVDS1 --off
	xrandr --output HDMI1 --off
	xrandr --output VGA1 --auto --right-of LVDS1
else
	echo "No external monitors are plugged in"
	#  xrandr --output LVDS1 --off
	xrandr --output HDMI1 --off
	xrandr --output VGA1 --off
	#  xrandr --output LVDS1 --mode 1366x768 --primary
fi
