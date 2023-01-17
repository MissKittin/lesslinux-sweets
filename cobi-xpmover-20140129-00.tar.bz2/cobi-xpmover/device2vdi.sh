#!/bin/bash

src="$1"
tgt="$2"
size="$3"

dd if="${src}" | /usr/local/VirtualBox/VBoxManage convertfromraw stdin "${tgt}" "${size}"
