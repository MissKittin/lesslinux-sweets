#!/bin/sh

echo $1
echo $2
[ -z $1 ] && exit 1
[ -z $2 ] && exit 1 

cp $1 ${1}.aux
cp $2 $1
cp ${1}.aux $2 
rm  ${1}.aux



