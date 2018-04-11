#!/bin/sh

# En attendant de pouvoir utiliser Git...
# Created: Apr. 03, 2018
# Author: Nabil LAMRABET

# -------------------------- creation du fichier log ---------------------------

dToday=`date -dtoday +%d-%m-%Y-%Hh%M`
dFile=anomaly-diagnostic-file-$dToday.adf
tmp=tmp.adf

touch dFile
touch tmp

echo "-------------------------- Anomaly Diagnostic File : $dToday ------------\
--------------" >> dfile

# -------------------------- detection des anomalies ---------------------------

printf "Detection des anomalies, cela peut prendre quelques temps..."

# on parcourt tous les dossiers clients
# for i in `find -maxdepth 1 -type d`
find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' line;
do
	printf "Verification du dossier client $i..."
	# numberOfNonExpectedFolders= find -mindepth 1 -maxdepth 1 -type d -print |
	#grep -v -E 'PAIES|LDM CLARTEO|Millesimes|^2[0-9]{3}(03|12)?$' | wc -l)

	# on écrit dans un fichier temporaire la liste des fichiers anormaux
	# (se trouvant à la racine d'un dossier client)
	find $line -mindepth 1 -maxdepth 1 -type f > $tmp

	numberOfNonExpectedFiles=$(wc -l tmp.adf | cut -d" " -f1)
	# on compte le nombre de fichiers, s'il y en a au moins un
	if [ $numberOfNonExpectedFiles -gt 0 ]
	then
		echo "Des fichiers se trouvent à la racine du dossier client $line : ." >> $dFile
		echo $tmp >> $dFile
	fi

	pathJ=`readlink -f $line`
	directoryJ=$(basename $pathJ)
	profondeur=$(echo $pathJ | grep -o "/" | wc -l) # profondeur
	profondeur=$(($profondeur+1))
	racine=5 # a changer

	for r in `find $file -mindepth 1 -maxdepth 1 -type d -print |
	grep -v -E 'PAIES|LDM CLARTEO|^2[0-9]{3}(03|12)?$'`
	do
		echo r >> fileDouble
		find $r -type d -print | grep -v -E 'PAIES|LDM CLARTEO|^2[0-9]{3}(03|12)?$' >> fileDouble
	done
done

numberofLineFileDouble=$(wc -l fileDouble | cut -d' ' -f1)
# on parcourt notre fichier comportant la liste des dossiers anormaux

for c in numberofLineFileDouble
do
	# on extrait du path uniquement le nom des dossiers
	# exemple :
	# /a/b/c -> c
	basename `head -$c fileDouble  | tail -1` >> fileDouble2
done

	find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' line;
	do
		$count=0
		for z in `cut -d' ' -f2 fileDouble2`
		do
			$count=$(($count+1))
			if [ `basename $line` = $z ]
			then
				echo $line >> fileDouble
				value=`head -$count fileDouble2  | tail -1 | cut -d' ' -f1`
				sed -i 's/$value/$(($value+1))/' file.txt
		done
	done

	sort fileCount2 | uniq -c > fileDouble2
