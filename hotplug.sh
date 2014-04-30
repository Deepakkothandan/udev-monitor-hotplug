#!/bin/bash
# Title:		hotplug.sh
# Description:	see README.md
# Author:		gehidore
# Date:			2014-02-12
# Version:		0.0.2-generic
# Usage:		see README.md
#
# TODO:			clean up code where possible
# TODO:			add more useful comments
# TODO:			fix Xauthority conflict when user is using a display manager such as LightDM
# TODO:			fix disconnect issue with device names...
# FIXED:		more than one external screen at a time
# Fixed:		disconnect of VGA1 and HDMI1 screens

# Functions cause they're awesome and more versatile

# setup display link device
function setup_displaylink() {
	local PROVIDERS=$(xrandr --listproviders)
	local DLPROVIDER=$(echo "$PROVIDERS" | grep modesetting)
	local DISPLAYLINKID=$(echo "$DLPROVIDER" | cut -d ' ' -f 2 | tr -d ':')
	local DLATTACHED=$(echo $DLPROVIDER | sed s/'.*associated providers: \([^ ]\+\).*'/\\1/)
	local DEFAULTPROVIDER="0"

	if [[ "$DLATTACHED" -eq "0" ]]
	then
		xrandr --setprovideroutputsource "$DISPLAYLINKID" "$DEFAULTPROVIDER"
		xrandr --rmmode "1368x768_59.99" 1>/dev/null 2>&1
		xrandr --newmode "1368x768_59.99"  86.85  1368 1440 1584 1800  768 769 772 795  -HSync +Vsync
	fi

	local DLID="DVI-1-$(xrandr | grep DVI-1- | sed s/'DVI-1-\([^ ]\+\).*'/\\1/)"

	if [[ ! -z "$DLID" ]]
	then
		xrandr --addmode "$DLID" 1368x768_59.99
	fi

	echo "$DLID"
}

# get the outputs
function outputs() {
	local OUTPUTS=()
	local DEVICES=$(find /sys/class/drm/*/status)

	#this while loop declare the $HDMI1 $VGA1 $LVDS1 $DISPLAYLINK and others if they are plugged in
	while read l
	do
		local DIR=$(dirname $l);
		local STATUS=$(cat $l);
		local DEV=$(echo "$DIR" | cut -d\- -f 2-);

		case "$DEV" in
			HDMI-*-*)
				# remove the -*- part from HDMI-*-n
				local DEV=HDMI"${DEV#HDMI-?-}"
				;;
			DVI-I-*)
				# set this to the DL
				local DEV="DISPLAYLINK"
				;;
			*)
				local DEV=$(echo "$DEV" | tr -d '-')
				;;
		esac

		if [[ "connected" == "$STATUS" ]]
		then
			declare "$DEV"="yes"
		fi
	done <<< "$DEVICES"

	# setup the screens and turn them on or off as needed
	if [[ ! -z "$DISPLAYLINK" ]] && [[ ! -z "$HDMI1" ]] && [[ ! -z "$VGA1" ]]
	then
		echo "DisplayLink, VGA1, and HDMI1 - disable LVDS1"
		# DisplayLink, VGA1, and HDMI1 - disable LVDS1t
		# [VGA1 ][HDMI1]
		# [DL   ]
		local DL=$(setup_displaylink)
		xrandr --output LVDS1 --off \
			--output VGA1 --primary --preferred \
			--output HDMI1 --preferred --right-of VGA1 \
			--output $DL --mode 1368x768_59.99 --below VGA1

	elif [[ ! -z "$HDMI1" ]] && [[ ! -z "$VGA1" ]];
	then
		echo "VGA1 and HDMI1 - disable LVDS1"
		# VGA1 and HDMI1 - disable LVDS1
		# [VGA1 ][HDMI1]
		xrandr --output LVDS1 --off \
			--output VGA1 --primary --preferred \
			--output HDMI1 --preferred --right-of VGA1

	elif [[ ! -z "$HDMI1" ]] && [[ ! -z "$DISPLAYLINK" ]];
	then
		local DL=$(setup_displaylink)
		echo "VGA1 and HDMI1 - disable LVDS1"
		# VGA1 and HDMI1 - disable LVDS1
		#        [HDMI1]
		# [DL   ][LVDS1]
		xrandr --output LVDS1 --primary --preferred \
			--output VGA1 --off \
			--output HDMI1 --preferred --above LVDS1
			--output $DL --mode 1368x768_59.99 --left-of LVDS1

	elif [[ ! -z "$DISPLAYLINK" ]];
	then
		echo "LVDS1 and DisplayLink - disable HDMI1 and VGA1"
		# LVDS1 and DisplayLink - disable HDMI1 and VGA1
		# [LVDS1][DL   ]
		local DL=$(setup_displaylink)
		xrandr --output HDMI1 --off \
			--output LVDS1 --primary --preferred \
			--output $DL --mode 1368x768_59.99 --right-of LVDS1 --output VGA1 --off

	elif [[ ! -z "$VGA" ]];
	then
		echo "LVDS1 and VGA1 - disable HDMI1 and VGA1"
		# LVDS1 and VGA1 - disable HDMI1 and VGA1
		# [LVDS1][VGA1   ]
		local DL=$(setup_displaylink)
		local DLOFF="--output $DL --off"
		xrandr --output HDMI1 --off \
			--output LVDS1 --primary --preferred \
			$DLOFF \
			--output VGA1 --below LVDS1

	elif [[ ! -z "$HDMI" ]];
	then
		echo "LVDS1 and DisplayLink - disable HDMI1 and VGA1"
		# LVDS1 and DisplayLink - disable HDMI1 and VGA1
		# [LVDS1][DL   ]
		local DL=$(setup_displaylink)
		local DLOFF="--output $DL --off"
		xrandr --output HDMI1 --preferred --right-of LVDS1 \
			--output LVDS1 --primary --preferred \
			$DLOFF \
			--output VGA1 --off

	else
		echo "LVDS1 - disable VGA1 and HDMI1"
		# LVDS1 - disable VGA1 and HDMI1
		# [LVDS1]
		xrandr --output LVDS1 --primary --preferred \
			--output VGA1 --off --output HDMI1 --off

	fi
}

# begin
function init() {
	DLID=""
	DISPLAYNUM=$(ls /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##)
	export DISPLAY=":$DISPLAYNUM"

	# set for loginctl to support systemd
	if [[ $(loginctl list-sessions | grep -q seat0) -eq 0 ]]; then
		# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
		# export XAUTHORITY=$(ps -C X -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')
		local YOURUSER="" # change me to match your users homedir
		export XAUTHORITY="/home/$YOURUSER/.Xauthority"
	else
		echo "unable to find an X session"
		exit 1
	fi

	# setup the screens
	outputs
}

# auxiliary function for disconnect
function removedl() {
	local DISPLAYLINK=$(setup_displaylink)
	xrandr --output "$DISPLAYLINK" --off
}

if [[ $1 == "removedl" ]]
then
	removedl
else
	init
fi
