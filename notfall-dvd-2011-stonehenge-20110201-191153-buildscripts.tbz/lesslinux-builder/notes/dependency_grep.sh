grep ^hard ../../llbuild/stage02/build/wget-1.12.dependencies.txt | awk '{print "                        <dep>"$2"</dep>"}' | sort | ( echo '               <builddeps>' ; uniq ; echo '                </builddeps>'; )