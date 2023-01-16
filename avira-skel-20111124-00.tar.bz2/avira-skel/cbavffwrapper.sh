#!/bin/bash
export LC_ALL=de_DE.UTF-8
export LANGUAGE=de_DE:de
export LANG=de_DE.UTF-8
# FFVERSION=3.6.8
# exec /opt/firefox35/lib/firefox-${FFVERSION}/firefox -contentLocale de-DE -UILocale de-DE "$@"
exec /opt/firefox50/firefox -contentLocale de-DE -UILocale de-DE "$@"