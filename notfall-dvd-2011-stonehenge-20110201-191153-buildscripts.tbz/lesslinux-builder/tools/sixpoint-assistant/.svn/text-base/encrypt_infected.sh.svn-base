#!/bin/bash

if [ -f "${1}".vir ] ; then
	now=` date "+%Y%m%d%H%M%s" `
	outfile="${1}.vir.${now}"
else
	outfile="${1}.vir"
fi

echo "Encrypting file: ${1}"
bzip2 -c "${1}" | openssl bf -pass pass:virus  -out "${outfile}"
