#!/bin/sh

# Created: Apr. 03, 2018
# Author: Nabil LAMRABET

# ----------------------- suppression des dossiers vides -----------------------

# rmdir * 2> /dev/null || true

# -------------------------- creation du fichier log ---------------------------

dateOfTheDay=`date -dtoday +%d-%m-%Y-%Hh%M`
diagnosticFile=anomaly-diagnostic-file-$dateOfTheDay.txt
tmp=tmp.txt

touch diagnosticFile
touch tmp

echo "---------------- Anomaly Diagnostic File : $dateOfTheDay ----------------" >> dfile

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
	# s'il y en a au moins un on affiche un message d'erreur
	# dans notre fichier de diagnostique.
	numberOfNonExpectedFiles=$(wc -l tmp.txt | cut -d" " -f1)
	if [ $numberOfNonExpectedFiles -gt 0 ]
	then
		printf "Des fichiers anormaux ont été trouvés."
		printf "Ecriture des fichiers anormaux dans le fichier de diagnostique."
		echo "Des fichiers se trouvent à la racine du dossier client $clientDirectory : ." >> $diagnosticFile
		cat $tmp >> $diagnosticFile
	fi

	printf "Recherche de dossiers anormaux..."

	for i in `find $clientDirectory -maxdepth 1 -type d -print grep -v -E 'PAIES|LDM CLARTEO|^2[0-9]{3}(03|12)?$'`
	do
		echo $i >> abnormalDirectoriesPathFile
		find $i -type d -print | grep -v -E 'PAIES|LDM CLARTEO|^2[0-9]{3}(03|12)?$' >> abnormalDirectoriesPathFile
	done
done

printf "Traitement des données..."
# abnormalDirectoriesPathFile est un fichier comportant la liste
# des chemins d'accès aux dossiers anormaux.
# numberofAbnormalDirectories est le nombre de dossiers anormaux.
# abnormalDirectoriesNameFile est la liste des dossiers anormaux
# sans leur chemin d'accès.

numberofAbnormalDirectories=$(wc -l abnormalDirectoriesPathFile | cut -d' ' -f1)
# On parcourt notre fichier comportant la liste des dossiers anormaux.
for j in numberofAbnormalDirectories
do

	# on extrait du path uniquement le nom des dossiers, exemple :
	# /a/b/c -> c
	basename `head -$j abnormalDirectoriesPathFile  | tail -1` >> abnormalDirectoriesNameFile
done

printf "recherche de dossiers multiples..."

# Pour chaque dossier client,
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
	done
done

# ----------------------------Traitement des données----------------------------

	printf "Traitement des données..."

	# directoriesOccurrencesFile : contient le nombre d'occurence d'un dossier anormal
	# dans la GED  : même s'il n'apparaît qu'une seule fois exemple
	# 2 260001
	# 4 260003
	# 1 260004
	# 1 260006
	# 1 74
	sort abnormalDirectoriesNameFile | uniq -cd > directoriesOccurrencesFile

	# multipleOccurrencesDirectoriesFile : contient le nombre d'occurence d'un dossier anormal
	# dans la GED uniquement s'il apparaît plusieurs fois exemple  :
	# 2 260001
	# 4 260003
	# 6 260004
	sort abnormalDirectoriesNameFile | uniq -c > multipleOccurrencesDirectoriesFile

	# singleOccurrenceDirectoriesFile : contient le nombre d'occurence d'un dossier anormal
	# dans la GED  : même s'il n'apparaît qu'une seule fois exemple
	# 1 260004
	# 1 260006
	# 1 74
	grep ^1 directoriesOccurrencesFile | cut -d' ' -f2 > singleOccurrenceDirectoriesFile

	# correctSingleClientDirectoryFile : contient les dossiers clients valides mais qui ont
	# une localisation anormale
	# 1 260004
	# 1 260006
	# 1 74
	grep -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' \
	singleOccurrenceDirectoriesFile > correctSingleClientDirectoryFile

	# nonCorrectSingleClientDirectoryFile : contient les dossiers clients invalides
	# 1 74
	grep -v -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' \
	singleOccurrenceDirectoriesFile > nonCorrectSingleClientDirectoryFile

	for k in `cat multipleOccurrencesDirectoriesFile | cut -d' ' -f2`
	do
		grep $k abnormalDirectoriesNameFile >> multipleDirectoriesPathFile
	done

	for l in `cat correctSingleClientDirectoryFile`
	do
		grep $l abnormalDirectoriesNameFile >> correctSingleClientDirectoryPathFile
	done

	for m in `cat nonCorrectSingleClientDirectoryFile`
	do
		grep $m abnormalDirectoriesNameFile >> nonCorrectSingleClientDirectoryPathFile
	done


for n in `cat correctSingleClientDirectoryPathFile`
do
	if [ `find $n -maxdepth 1 | \
	grep -v -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' | \
	 wc -l` -eq 0 ]
	then
		cat $n >> clientDirectoryWithJustWrongLocation
done

echo "Dossiers ayant plusieurs occurrences :"
cat multipleDirectoriesPathFile >> $diagnosticFile

echo "Dossiers avec nom invalide ayant une seule occurrence :"
cat nonCorrectSingleClientDirectoryPathFile >> $diagnosticFile

echo "Dossiers avec nom valide ayant une seule occurrence :"
cat correctSingleClientDirectoryPathFile >> $diagnosticFile

echo "Dossiers avec nom valide, ayant une seule occurrence,
\ ne comportant pas de dossiers anormaux :"
cat clientDirectoryWithJustWrongLocation >> $diagnosticFile


cat multipleDirectoriesPathFile nonCorrectSingleClientDirectoryPathFile correctSingleClientDirectoryPathFile clientDirectoryWithJustWrongLocation tmp >> diag2

for o in `cat d2`
do
	nom=$(ls -ld --full-time $l | awk '{print $3}')
	da=$(ls -ld --full-time $l | awk '{print $8}')
	da=`date -d $da +%d/%m/%Y`
	heure=$(ls -ld $l | awk '{print $10}')

	echo "$o crée par $nom le $da a $heure" >> d3
done
