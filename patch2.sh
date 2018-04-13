#!/bin/sh
# Created: Apr. 13, 2018

printf "Les dossiers clients qui : \n
- ont un nom de dossier correct \n
- ont un contenu correct \n
- mais qui ne sont pas correctement localisés \n
seront déplacés"

for client in `cat clientDirectoryWithJustWrongLocation`
do
  root=$(echo $client | cut -d'/' -f1-2)
  printf "$client est déplacé dans $root"
  mv $client $root
done
