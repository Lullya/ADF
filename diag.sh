#!/bin/sh

# En attendant de pouvoir utiliser Git...
# Created: Apr. 03, 2018
# Author: Nabil LAMRABET


# creation du fichier log

dToday=`date -dtoday +%d-%m-%Y-%Hh%M`
dFile=anomaly-diagnostic-file-$dToday.adf
dNonExpectedFiles=non-expected-files-$dToday.adf

touch dFile

echo "-------------------------- Anomaly Diagnostic File : $dtoday --------------------------" >> dfile



# detection des anomalies

printf "Detection des anomalies, cela peut prendre quelques temps..."

# for i in `find -maxdepth 1 -type d` 
find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' line;
# on parcourt tous les dossiers client
do
	printf "Verification du dossier client $i..."
	#numberOfNonExpectedFolders= find -mindepth 1 -maxdepth 1 -type d -print | grep -v -E 'PAIES|LDM CLARTEO|Millesimes|^2[0-9]{3}(03|12)?$' | wc -l)
	
	echo 
	find $line -mindepth 1 -maxdepth 1 -type f > tmp.adf
	numberOfNonExpectedFiles=$(wc -l tmp.adf | cut -d" " -f1)

	if [ $numberOfNonExpectedFiles -gt 0 ]
		then
			echo "Des fichiers se trouvent à la racine du dossier client $line : ." >> dFile
			tmp.adf >> dFile
	fi

		printf "Verification du sous dossier $i..."
		repertoirCourantJ=$(basename `pwd`)
		pathJ=`pwd`
		profondeur=echo `pwd` | grep -o "/" | wc -l # profondeur
		profondeur=$(($profondeur-3)) # a changer
		

		for k in {1..$profondeur}
		do
			find -mindepth $k -maxdepth $k -type d -print | grep -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' | sort > tmp.adf
			#on cherche un dossier client valide
			nbsub=$(wc -l tmp.adf | cut -d" " -f1)
			#sub est un "ensemble" de dossier, je ne peux pas faire un wc sur cette variable

			if [ $nbsub -gt 0 ] # si on trouve des dossiers clients valides dans un dossier client valide
			then
				for l in `find -mindepth 1 -maxdepth 1 -type d -print | cut -d'/' -f2 |grep -E '^(26|27|84|87){1}[0-9]{4}$|^(28|88){1}[0-9]{4}(A|B|C){1}$' | sort`
				do
					# pour chaque sous dossier valide, on affiche dans un fichier le path de ces sous dossiers
					nom=$(ls -ld --full-time $l | awk '{print $3}')
					da=$(ls -ld --full-time $l | awk '{print $8}')
					da=`date -d $da +%d/%m/%Y`
					heure=$(ls -ld $l | awk '{print $10}')
					echo "Un dossier client se trouve dans un autre dossier client : `pwd`/$l - dossier cree par $nom le $da a $heure" >> dFile 
				done
			fi
	done
done

	# Pas propre, en attendant de pouvoir utiliser GIT...	
	#	l=pwd | cut -d "/" -f$k
	#	if [ $b == $l ]
	#		printf "le dossier utilisateur $k se trouve dans un autre dossier utilisateur  \t`pwd`"
	#	fi
	
	#	if [ $i == $b -o $i == $a ] ; then
	#		printf "le dossier utilisateur $i se trouve dans un autre dossier utilisateur  \t`pwd`"
	#	fi
