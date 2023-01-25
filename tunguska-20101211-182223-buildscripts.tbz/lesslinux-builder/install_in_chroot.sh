#!/bin/bash
cd /llbuild/build/linux_headers-2.6.36

. common_vars
SRCDIR=/llbuild/src; export SRCDIR
LC_ALL=POSIX; export LC_ALL


			
			cd linux-${PKGVERSION}
			make INSTALL_HDR_PATH=dest headers_install
			find dest/include \( -name .install -o -name ..install.cmd \) -delete
			cp -rv dest/include/* /usr/include
			
			

