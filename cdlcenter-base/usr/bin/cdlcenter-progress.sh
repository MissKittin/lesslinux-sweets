#/bin/sh
NR="1"
while true;
do
        case $NR in
        '1') NR='2'; ZNAK="/";;
        '2') NR='3'; ZNAK="-";;
        '3') NR='4'; ZNAK="\\";;
        '4') NR='5'; ZNAK="|";;
        '5') NR='6'; ZNAK="/";;
        '6') NR='7'; ZNAK="-";;
        '7') NR='8'; ZNAK="\\";;
        '8') NR='1'; ZNAK="|";;
        esac
        echo -en "\b"
        echo -en $ZNAK
        sleep 1
done
													
