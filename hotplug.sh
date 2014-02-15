#!/bin/bash
# Title:		hotplug.sh
# Description:	see README.md
# Author:		gehidore
# Date:			2014-02-12
# Version:		0.0.1
# Usage:		see README.md
#
# TODO:			clean up code where possible
# TODO:			add more useful comments
# TODO:			fix Xauthority conflict when user is using a display manager such as LightDM
# TODO:			support more than one external monitor at a time
# TODO:			fix disconnect issue with device names...
# TODO:			fix focused workspace failure when adding screen
# FIXED:		i3-wm crash on hotplug

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
	local MSG=$(i3-msg -t get_workspaces | json_pp)
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

	if [[ ! -z $1 ]]
	then
		SCREEN="$1"
	fi

	# loop through workspaces in reverse 10-5 and move them to the new output, return to the initial focused workspace.
	for ID in {9..5}
	do
		# echo "$ID"
		# echo "$SCREEN"
		# echo "$WORKSPACE"
		i3-msg -q "workspace $ID; move workspace to output $SCREEN; workspace $WORKSPACE;"
	done
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
			OUTPUTS+=("$DEV")
		fi
	done <<< "$DEVICES"

	# setup the screens and turn them on or off as needed
	for OUTPUT in "${OUTPUTS[@]}"
	do
		case "$OUTPUT" in
			HDMI*)
				local HDMI="--output $OUTPUT --preferred --below LVDS1 --rotate normal"
				;;
			DISPLAYLINK)
				local DL=$(setup_displaylink)
				local DISPLAYLINK="--output $DL --mode 1368x768_59.99 --right-of LVDS1 --rotate normal"
				;;
			VGA*)
				local VGA="--output $OUTPUT --preferred --below LVDS1 --rotate normal"
				;;
		esac
	done
	xrandr $(echo "$DISPLAYLINK" "$HDMI" "$VGA")
	workspaces $DL
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
