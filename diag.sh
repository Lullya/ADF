#!/bin/sh

# Created: Apr. 03, 2018
# Author: Nabil LAMRABET

# ----------------------- suppression des dossiers vides -----------------------

# rmdir * 2> /dev/null || true

# -------------------------- creation du fichier log ---------------------------

format()
{
	FILE_TO_FORMAT=$1
	FILE_WITH_DATA=$2
	FILE_TO_WRITE=$3
	while IFS= read -r o;
	do
		nom=$(ls -ld --full-time "${o}" | awk '{print $3}')
		da=$(ls -ld --full-time "${o}" | awk '{print $6}')
		da=`date -d $da +%d/%m/%Y`
		heure=$(ls -ld "${o}" | awk '{print $8}')

		echo "$o | $nom | $da | $heure" >> $FILE_WITH_DATA
	done < "$FILE_TO_FORMAT"

	column -t $FILE_WITH_DATA -s'|' >> $FILE_TO_WRITE
	rm -r $FILE_WITH_DATA
}

dateOfTheDay=`date -dtoday +%d-%m-%Y-%Hh%M`
diagnosticFile=anomaly-diagnostic-file-$dateOfTheDay

touch $diagnosticFile

echo "---------------- Anomaly Diagnostic File : $dateOfTheDay ----------------" >> $diagnosticFile

> tmpFilesP.adfp
> tmpDirectoriesP.adfp
> directoriesOccurrencesN.adfp
> multipleOccurrencesDirectoriesN.adfp
> multipleDirectoriesP.adfp


> singleOccurrenceDirectoriesN.adfp

> noncorrectSingleClientDirectoryN.adfp
> noncorrectSingleClientDirectoryP.adfp

> correctSingleClientDirectoryN.adfp
> correctSingleClientDirectoryP.adfp

> correctSingleClientDirectoryWithContentP.adfp
> correctSingleClientDirectoryWithNoContentP.adfp


>filesP.adfp
>directoriesP.adfp

>abnormalDirectoriesP.adfp
>abnormalDirectoriesN.adfp

# -------------------------- detection des anomalies ---------------------------
printf "Detection des anomalies, cela peut prendre quelques temps\n"

# On parcourt tous les dossiers clients.
#find . -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' clientDirectory;
find . -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' -r clientDirectory;
do

	# On écrit dans un fichier temporaire la liste des fichiers anormaux
	# (se trouvant à la racine d'un dossier client).
	find "${clientDirectory}" -mindepth 1 -maxdepth 1 -type f > tmpFilesP.adfp

	# On écrit dans un fichier temporaire la liste des dossiers anormaux
	# (se trouvant à la racine d'un dossier client).
	# On considère qu'il s'agit de tout autre dossier que PAIES, LDM CLARTEO,
	# une année (ex : 2016) ou une année-mois (ex : 201612).
	find "${clientDirectory}" -mindepth 1 -type d | grep -v -E 'PAIES|LDM CLARTEO|20[0-9]{2}((0|1){1}[0-9]{1})?$' > tmpDirectoriesP.adfp

	# On compte le nombre de fichiers anormaux.
	numberOfNonExpectedFiles=$(wc -l tmpFilesP.adfp | cut -d" " -f1)

	# Pareil on compte le nombre de dossiers anormaux.
	numberOfNonExpectedDirectories=$(wc -l tmpDirectoriesP.adfp | cut -d" " -f1)

	# S'il y a au moins un fichier on affiche un message d'erreur dans un fichier filesP.adfp.
	# On fait pareil pour les dossiers anormaux.
	# Cette condition sert uniquement à ne pas créer de message d'erreur si le dossier client est sain.

	if [ $numberOfNonExpectedFiles -gt 0 ]
	then
		printf "\t Des fichiers anormaux ont été trouvés dans le dossier client $clientDirectory\n"
		printf "\n------------------------- racine du dossier client $clientDirectory :\n" >> filesP.adfp
		format tmpFilesP.adfp tmpFilesP2.adfp filesP.adfp
	fi

	if [ $numberOfNonExpectedDirectories -gt 0 ]
	then
		printf "\t Des dossiers anormaux ont été trouvés dans le dossier client $clientDirectory\n"
		printf "\n------------------------- dossier client $clientDirectory :\n" >> directoriesP.adfp
		format tmpDirectoriesP.adfp tmpDirectoriesP2.adfp directoriesP.adfp
	fi

	# On écrit le chemin des fichiers et dossiers anormaux dans 2 autres fichiers
	# sans écrire aucun message d'erreur afin d'avoir uniquement des chemins d'accès.
	cat tmpDirectoriesP.adfp >> abnormalDirectoriesP.adfp
done

cat filesP.adfp directoriesP.adfp >> $diagnosticFile

printf "Recherche des dossiers multiples\n"

# abnormalDirectoriesP.adfp est un fichier comportant la liste
# des chemins d'accès aux dossiers anormaux.
# numberofAbnormalDirectories est le nombre de dossiers anormaux.
# abnormalDirectoriesN.adfp est la liste des dossiers anormaux
# sans leur chemin d'accès.

numberofAbnormalDirectories=$(wc -l abnormalDirectoriesP.adfp | cut -d' ' -f1)
# On parcourt notre fichier comportant la liste des dossiers anormaux.
for j in $(seq 1 $numberofAbnormalDirectories)
do
	# on extrait du path uniquement le nom des dossiers, exemple :
	# /a/b/c -> c
	basename "`head -$j abnormalDirectoriesP.adfp  | tail -1`" >> abnormalDirectoriesN.adfp
done

# Pour chaque dossier client,
find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' currentClientDirectory;
do
	count=0

	# et pour chaque dossier anormalement localisé,
	for currentAnormalDirectory in `cat abnormalDirectoriesN.adfp`
	do
		count=$(($count+1))

		# on compare si le dossier client et le dossier anormal portent le même nom,
		baseCurrentClientDirectory=`basename "$currentClientDirectory"`
		if [ "$baseCurrentClientDirectory" == "$currentAnormalDirectory" ]
		then
			printf "\t Dossiers multiples trouvés $currentClientDirectory \n"
			if [ `cat abnormalDirectoriesP.adfp | grep -E ^"$currentClientDirectory"$ | wc -l` -eq 0 ]
			then
				# dans ce cas on ajoute le chemin d'accès du dossier clients
				# à la liste des chemins d'accès de dossiers anormaux
				echo $currentClientDirectory >> abnormalDirectoriesP.adfp

				# et on ajoute le nom du dossier à la liste des dossiers anormaux.
				echo `basename $currentClientDirectory` >> abnormalDirectoriesN.adfp
			fi
		fi
	done
done

# ----------------------------Traitement des données----------------------------

printf "\t Traitement des données\n"

# directoriesOccurrencesN.adfp : contient le nombre d'occurence d'un dossier anormal
# dans la GED  : même s'il n'apparaît qu'une seule fois exemple
# 2 260001
# 4 260003
# 1 260004
# 1 260006
# 1 74
sort abnormalDirectoriesN.adfp | uniq -c | sed 's/^ *//' > directoriesOccurrencesN.adfp
# multipleOccurrencesDirectoriesN.adfp : contient le nombre d'occurence d'un dossier anormal
# dans la GED uniquement s'il apparaît plusieurs fois exemple  :
# 2 260001
# 4 260003
# 6 260004
sort abnormalDirectoriesN.adfp | uniq -cd | sed 's/^ *//' > multipleOccurrencesDirectoriesN.adfp

# singleOccurrenceDirectoriesN.adfp : contient le nombre d'occurence d'un dossier anormal
# dans la GED  : même s'il n'apparaît qu'une seule fois exemple
# 1 260004
# 1 260006
# 1 74
grep ^1 directoriesOccurrencesN.adfp | cut -d' ' -f2 > singleOccurrenceDirectoriesN.adfp

# correctSingleClientDirectoryN.adfp : contient les dossiers clients valides mais qui ont
# une localisation anormale
# 1 260004
# 1 260006
# 1 74
grep -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' singleOccurrenceDirectoriesN.adfp > correctSingleClientDirectoryN.adfp

# noncorrectSingleClientDirectoryN.adfp : contient les dossiers clients invalides
# 1 74
grep -v -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' singleOccurrenceDirectoriesN.adfp > noncorrectSingleClientDirectoryN.adfp

for k in `cat multipleOccurrencesDirectoriesN.adfp | cut -d' ' -f2`
do
	grep "${k}" abnormalDirectoriesP.adfp >> multipleDirectoriesP.adfp
done

for l in `cat correctSingleClientDirectoryN.adfp`
do
	grep "${l}"$ abnormalDirectoriesP.adfp >> correctSingleClientDirectoryP.adfp
done

for m in `cat noncorrectSingleClientDirectoryN.adfp`
do
	grep "${m}" abnormalDirectoriesP.adfp >> noncorrectSingleClientDirectoryP.adfp
done


for n in `cat correctSingleClientDirectoryP.adfp`
do
	if [ `find "${n}" -mindepth 1 -maxdepth 1 -type d |	grep -v -E 'PAIES|LDM CLARTEO|20[0-9]{2}((0|1){1}[0-9]{1})?$' | wc -l` -eq 0 ]
	then
		echo "${n}" >> correctSingleClientDirectoryWithNoContentP.adfp
	else
		echo "${n}" >> correctSingleClientDirectoryWithContentP.adfp

	fi
done

printf "\n------------------------------------------------------------------------\nDossiers ayant plusieurs occurrences :\n" >> $diagnosticFile
format multipleDirectoriesP.adfp multipleDirectoriesP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom invalide ayant une seule occurrence :\n" >> $diagnosticFile
format noncorrectSingleClientDirectoryP.adfp noncorrectSingleClientDirectoryP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom valide ayant une seule occurrence :\n" >> $diagnosticFile
format correctSingleClientDirectoryWithContentP.adfp correctSingleClientDirectoryWithContentP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom valide, ayant une seule occurrence, ne comportant pas de dossiers anormaux :\n" >> $diagnosticFile
format correctSingleClientDirectoryWithNoContentP.adfp correctSingleClientDirectoryWithNoContentP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\ndossier à la racine non valide\n" >> $diagnosticFile
find . -mindepth 1 -maxdepth 1 -type d | grep -v -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C){1}$' >> badDirectories.adfp
format badDirectories.adfp badDirectories2.adfp $diagnosticFile


rm -r *.adfp

printf "Diagnostic des anomalies terminé\n"
