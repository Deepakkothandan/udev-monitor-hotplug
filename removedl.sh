#!/bin/sh
DLID="DVI-1-$(xrandr | grep DVI-1- | sed s/'DVI-1-\([^ ]\+\).*'/\\1/)"
xrandr --output "$DLID" --off
