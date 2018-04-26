#!/bin/sh

for i in `cat d.txt`
do
find "${i}" -type f
rm -r "${i}"
done
