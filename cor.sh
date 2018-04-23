#!/bin/sh

# Created: Apr. 23, 2018

find . -mindepth 1 -maxdepth 1 -type d -regextype posix-egrep -regex '^(./)?(26|84){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}$' -print0 | while IFS= read -r -d '' -r client;
do
  echo "${client}"

  if [ `find "${client}" -mindepth 1 -maxdepth 1 -type d | grep -E 'PAIES' | wc -l` -eq 0 ]
  then
    mkdir ${client}/PAIES
  else
    for i in $(seq 2005 2020)
    do
      if [ `find "${client}/PAIES" -type f -name '*$i*' | wc -l` -gt 0 ]
      then
      mkdir ${client}/PAIES/${i} 2> /dev/null || true
      find "${client}/PAIES" -type f -name '*$i*' -exec mv -t ${client}/PAIES/$i {} +
      fi
    done
  fi
  echo "test"
  find "${client}" -mindepth 1 -maxdepth 1 -type d -regextype posix-egrep -regex "${client}/(20|19){1}[0-9]{2}$" -print0 | while IFS= read -r -d '' -r annee;
  do
    echo "${annee}"
    year=$(echo "${annee}" | cut -d'/' -f3)
    if [ `find "${annee}" -mindepth 1 -maxdepth 1 -type d | grep -E 'ISAPAYE' | wc -l` -eq 1 ]
    then
    mkdir ${client}/PAIES/${year} 2> /dev/null || true
    find "${client}/${year}/ISAPAYE" -mindepth 1 -type f -exec mv -t ${client}/PAIES/${year} {} +
    rmdir -p ${client}/${year}/ISAPAYE/*
    fi
  done
done
