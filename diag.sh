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

	# on cherche des dossiers clients valides et on les écrit temporairement
	find $file -type d -print | \
	grep -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' | \
	sort > tmp.adf

	# nbsub est le nombre de dossiers clients valides
	nbsub=$(wc -l tmp.adf | cut -d" " -f1)

	# si on trouve des dossiers clients valides dans un dossier client valide
	if [ $nbsub -gt 0 ]
	then
		for l in `find $file -type d -print | \
		cut -d'/' -f2 | \
		grep -E '^(26|27|84|87){1}[0-9]{4}$|^(28|88){1}[0-9]{4}(A|B|C){1}$' | \
		sort`
		do
			# on compare le nom du sous dossier client (anormal) $l avec :
			# les dossiers parents
			# les dossiers clients à la racine de la GED

			pathL=`readlink -f $l`
			directoryL=$(basename $pathL)
			nom=$(ls -ld --full-time $l | awk '{print $3}')
			da=$(ls -ld --full-time $l | awk '{print $8}')
			da=`date -d $da +%d/%m/%Y`
			heure=$(ls -ld $l | awk '{print $10}')

			# on souhaite compter le nombre de dossier parent comportant le même nom
			$count=0

			# exemple :
			# /cygdrive/z/Isagri/GEDCFC/26/260221/262001/260221/26/262001
			# profondeur=11
			# racine=5
			# on veut comparer 262001 avec 260221 262001 260221
			for m in {$profondeur-1..$racine)
			do
				# pour chaque sous dossier valide,
				#on affiche dans un fichier le path de ces sous dossiers
				aParentDirectory=$(echo $pathL | cut -d'/' -f$m)
				aParentPath=$(echo $pathL | cut -d'/' -f1-$m)
				if [ $directory = $aParentDirectory ]
				then
					echo "2 - Un dossier client se trouve dans un autre dossier client,\
					attention ; ce dossier comporte le même nom que le dossier parent $aParentPath :
					`pwd`/$l - dossier cree par $nom le $da a $heure" >> dFile
					$count=$(($count+1))
				fi
			done

			if [ $count -eq 0]
			then
				echo "1 - Un dossier client se trouve dans un autre dossier client : \
				`pwd`/$l - dossier cree par $nom le $da a $heure" >> dFile
			else
				echo "nombre de dossier parent comportant le même nom : $count" >> dFile
			fi
		done

		find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' line2;
		do
			nameLine2= echo line2 | cut -d"/" -f2
			if [ $nameLine2 = $l]
				echo "3 - ce dossier comporte le même nom que le dossier client $aParentPath :
				`pwd`/$l - dossier cree par $nom le $da a $heure" >> dFile
			then
			fi
		done
	fi
done
