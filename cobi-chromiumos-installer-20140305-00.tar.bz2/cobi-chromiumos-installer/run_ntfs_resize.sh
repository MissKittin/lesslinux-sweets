#!/bin/bash
yes y | ntfsresize --no-progress-bar --force --size "$1" "/dev/${2}"
