#!/bin/sh

# Created: Apr. 03, 2018
# Author: Nabil LAMRABET

# -------------------------- creation du fichier log ---------------------------

dateOfTheDay=`date -dtoday +%d-%m-%Y-%Hh%M`
diagnosticFile=anomaly-diagnostic-file-$dateOfTheDay.adf
tmp=tmp.adf

touch diagnosticFile
touch tmp

echo "-------------------------- Anomaly Diagnostic File : $dateOfTheDay ------------\
--------------" >> dfile

# -------------------------- detection des anomalies ---------------------------

printf "Detection des anomalies, cela peut prendre quelques temps..."

# On parcourt tous les dossiers clients.
find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' clientDirectory;
do
	printf "Verification du dossier client $clientDirectory..."

	printf "Recherche de fichiers anormaux à la racine..."

	# On écrit dans un fichier temporaire la liste des fichiers anormaux
	# (se trouvant à la racine d'un dossier client).
	find $clientDirectory -maxdepth 1 -type f >> $tmp

	# On compte le nombre de fichiers anormaux,
	# s'il y en a au moins un on affiche un message d'erreur dans notre fichier de diagnostique.
	numberOfNonExpectedFiles=$(wc -l tmp.adf | cut -d" " -f1)
	if [ $numberOfNonExpectedFiles -gt 0 ]
	then
		printf "Des fichiers anormaux ont été trouvés."
		printf "Ecriture des fichiers anormaux dans le fichier de diagnostique."
		echo "Des fichiers se trouvent à la racine du dossier client $clientDirectory : ." >> $diagnosticFile
		echo $tmp >> $diagnosticFile
	fi

	printf "Recherche de dossiers anormaux..."

	clientDirectoryPath=`readlink -f $clientDirectory`
	clientDirectoryName=`basename $clientDirectoryPath`
	profondeur=$(echo $clientDirectoryPath | grep -o "/" | wc -l) # profondeur
	profondeur=$(($profondeur+1))
	racine=5 # a changer

	for i in `find $clientDirectory -maxdepth 1 -type d -print grep -v -E 'PAIES|LDM CLARTEO|^2[0-9]{3}(03|12)?$'`
	do
		echo $i >> abnormalDirectoriesPathFile
		find $i -type d -print | grep -v -E 'PAIES|LDM CLARTEO|^2[0-9]{3}(03|12)?$' >> abnormalDirectoriesPathFile
	done
done

printf "Traitement des données..."
# abnormalDirectoriesPathFile est un fichier comportant la liste des chemins d'accès aux dossiers anormaux.
# numberofAbnormalDirectories est le nombre de dossiers anormaux.
# abnormalDirectoriesNameFile est la liste des dossiers anormaux sans leur chemin d'accès.

numberofAbnormalDirectories=$(wc -l abnormalDirectoriesPathFile | cut -d' ' -f1)
# On parcourt notre fichier comportant la liste des dossiers anormaux.
for c in numberofAbnormalDirectories
do

	# on extrait du path uniquement le nom des dossiers, exemple :
	# /a/b/c -> c
	basename `head -$c abnormalDirectoriesPathFile  | tail -1` >> abnormalDirectoriesNameFile
done

# Pour chaque dossier client,

printf "recherche de dossiers multiples..."

find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' currentClientDirectory;
do
	$count=0

	# et pour chaque dossier anormalement localisé,
	for currentAnormalDirectory in `cat abnormalDirectoriesNameFile`
	do
		$count=$(($count+1))

		# on compare si le dossier client et le dossier anormal portent le même nom,
		if [ `basename $currentClientDirectory` = $currentAnormalDirectory ]
		then
			printf "Dossiers multiples trouvés."
			printf "Ecriture des dossiers multiples dans le fichier de diagnostique."

			# dans ce cas on ajoute le chemin d'accès du dossier clients
			# à la liste des chemins d'accès de dossiers anormaux
			echo $currentClientDirectory >> abnormalDirectoriesPathFile

			# et on ajoute le nom du dossier à la liste des dossiers anormaux.
			echo `basename $currentClientDirectory` >> abnormalDirectoriesNameFile

			#	v1=`head -$count abnormalDirectoriesNameFile  | tail -1 | cut -d' ' -f1`
			#	v2=$(($v1+1))
			#	vtext=`head -$count abnormalDirectoriesNameFile  | tail -1 | cut -d' ' -f2`
			#	sed -i '/$v1/ c\$v2 vtext' file.txt
	done
done

	printf "Traitement des données..."
	sort abnormalDirectoriesNameFile | uniq -c > multipleDirectoriesFile
