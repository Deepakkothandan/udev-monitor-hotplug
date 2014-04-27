#!/bin/bash
# Title:		hotplug.sh
# Description:	see README.md
# Author:		gehidore
# Date:			2014-02-12
# Version:		0.0.2
# Usage:		see README.md
#
# TODO:			clean up code where possible
# TODO:			add more useful comments
# TODO:			fix Xauthority conflict when user is using a display manager such as LightDM
# TODO:			fix disconnect issue with device names...
# TODO:			fix focused workspace failure when adding screen
# FIXED:		i3-wm crash on hotplug
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

# set and recover workspaces as needed
function workspaces() {
	local SCREEN="LVDS1"
	local MSG=$(i3-msg -t get_workspaces | /usr/bin/core_perl/json_pp)
	local NAMES=$(echo "$MSG" | grep 'name' | sed s/'"name" : "\([^ ]\+\).*".*'/\\1/ | tr -d ' ')
	local FOCUSED=$(echo "$MSG" | grep 'focused' | sed -e 's/"focused" : //g' -e 's/,//g' | tr -d ' ')
	local COUNT=$(echo "$NAMES" | wc -l)

	for LINE in $(seq 1 "$COUNT")
	do
		TF=$(echo "$FOCUSED" | sed -n "$LINE"p)
		if [[ "$TF" == "true" ]]
		then
			WORKSPACE=$(echo "$NAMES" | sed -n "$LINE"p)
			continue
		fi
	done

	if [[ ! -z "$3" ]] || [[ ! -z "$3" ]]
	then
		if [[ "HDMI1" == "$2" ]]
		then
			# HDMI1
			for ID in {10..5}
			do
				i3-msg -q "workspace $ID; move workspace to output HDMI; workspace $WORKSPACE;"
			done
		fi

		if [[ "VGA1" == "$3" ]]
		then
			# VGA1
			for ID in {6,4}
			do
				i3-msg -q "workspace $ID; move workspace to output VGA1; workspace $WORKSPACE;"
			done
		fi

		if [[ ! -z "$1" ]]
		then
			SCREEN="$1"
			# DL
			for ID in {3..1}
			do
				i3-msg -q "workspace $ID; move workspace to output $SCREEN; workspace $WORKSPACE;"
			done
		fi
	else

		if [[ ! -z "$1" ]]
		then
			SCREEN="$1"
		fi

		# loop through workspaces in reverse 9-5 and move them to the new output, return to the initial focused workspace.
		for ID in {9..5}
		do
			# echo "$ID"
			# echo "$SCREEN"
			# echo "$WORKSPACE"
			if [[ 5 -eq "$ID" && ! -z "$2" ]]
			then
				SCREEN="$2"
			fi
			i3-msg -q "workspace $ID; move workspace to output $SCREEN; workspace $WORKSPACE;"
		done

	fi
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
		# DisplayLink, VGA1, and HDMI1 - disable LVDS1
		# [VGA1 ][HDMI1]
		# [DL   ]
		local DL=$(setup_displaylink)
		xrandr --output LVDS1 --off \
			--output VGA1 --primary --preferred \
			--output HDMI1 --preferred --right-of VGA1 \
			--output $DL --mode 1368x768_59.99 --below VGA1
		workspaces "$DL" "HDMI" "VGA1"

	elif [[ ! -z "$HDMI1" ]] && [[ ! -z "$VGA1" ]];
	then
		# VGA1 and HDMI1 - disable LVDS1
		# [VGA1 ][HDMI1]
		xrandr --output LVDS1 --off \
			--output VGA1 --primary --preferred \
			--output HDMI1 --preferred --right-of VGA1
		workspaces "" "HDMI1" "VGA1"

	elif [[ ! -z "$DISPLAYLINK" ]];
	then
		# LVDS1 and DisplayLink - disable HDMI1 and VGA1
		# [LVDS1][DL   ]
		local DL=$(setup_displaylink)
		xrandr --output HDMI1 --off \
			--output LVDS1 --primary --preferred \
			--output $DL --mode 1368x768_59.99 --right-of LVDS1 --output VGA1 --off
		workspaces "$DL"

	elif [[ ! -z "$VGA" ]];
	then
		# LVDS1 and VGA1 - disable HDMI1 and VGA1
		# [LVDS1][VGA1   ]
		local DL=$(setup_displaylink)
		local DLOFF="--output $DL --off"
		xrandr --output HDMI1 --off \
			--output LVDS1 --primary --preferred \
			$DLOFF \
			--output VGA1 --below LVDS1
		workspaces "" "" "VGA1"

	elif [[ ! -z "$HDMI" ]];
	then
		# LVDS1 and DisplayLink - disable HDMI1 and VGA1
		# [LVDS1][DL   ]
		local DL=$(setup_displaylink)
		local DLOFF="--output $DL --off"
		xrandr --output HDMI1 --preferred --right-of LVDS1 \
			--output LVDS1 --primary --preferred \
			$DLOFF \
			--output VGA1 --off
		workspaces "" "HDMI1"

	else
		# LVDS1 - disable VGA1 and HDMI1
		# [LVDS1]
		xrandr --output LVDS1 --primary --preferred \
			--output VGA1 --off --output HDMI1 --off
		workspaces

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
		export XAUTHORITY="/home/gehidore/.Xauthority"
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
	workspaces
	xrandr --output "$DISPLAYLINK" --off
}

if [[ $1 == "removedl" ]]
then
	removedl
else
	init
fi
