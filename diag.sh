#!/bin/sh

# Created: Apr. 03, 2018
# Author: Nabil LAMRABET

# ----------------------- suppression des dossiers vides -----------------------

# rmdir * 2> /dev/null || true




dateOfTheDay=`date -dtoday +%d-%m-%Y-%Hh%M`



touch tmpFilesP.adfp

touch tmpDirectoriesP.adfp

touch directoriesOccurrencesN.adfp
touch multipleOccurrencesDirectoriesN.adfp
touch multipleDirectoriesP.adfp

touch singleOccurrenceDirectoriesN.adfp

touch noncorrectSingleClientDirectoryN.adfp
touch noncorrectSingleClientDirectoryP.adfp

touch correctSingleClientDirectoryN.adfp
touch correctSingleClientDirectoryP.adfp
touch correctSingleClientDirectoryWithContentP.adfp
touch correctSingleClientDirectoryWithNoContentP.adfp


touch abnormalDirectoriesN.adfp

touch fichierDoubles.adfp

touch nomClients.adfp

touch tmpDirectoriesP2.adfp
# -------------------------- detection des anomalies ---------------------------
printf "Detection des anomalies, cela peut prendre quelques temps\n"

# On parcourt tous les dossiers clients.
#find . -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' clientDirectory;
find . -mindepth 1 -maxdepth 1 -type d -regextype posix-egrep -regex '^(./)?[0-9]*' -print0 | while IFS= read -r -d '' -r clientDirectory;
do
		printf "$clientDirectory\n"

		# On écrit dans un fichier temporaire la liste des fichiers anormaux
		# (se trouvant à la racine d'un dossier client).
		# find "${clientDirectory}" -mindepth 1 -maxdepth 1 -type f >> tmpFilesP.adfp

		# On écrit dans un fichier temporaire la liste des dossiers anormaux
		# (se trouvant à la racine d'un dossier client).
		# On considère qu'il s'agit de tout autre dossier que PAIES, LDM CLARTEO,
		# une année (ex : 2016) ou une année-mois (ex : 201612).
		find "${clientDirectory}" -mindepth 1 -maxdepth 1 -type d | grep -v -E 'PAIES|LDM CLARTEO|(20|19)[0-9]{2}((0|1){1}[0-9]{1})?$' >> tmpDirectoriesP.adfp
done


echo "1"
for i in `cat tmpDirectoriesP.adfp`
do
	name=$(basename "${i}")

	if [ `echo "${name}" | grep -E '^[0-9]{5,7}(A|B|C)?' | wc -l` -eq 1 ]
	then
	find "${i}" -mindepth 1 -maxdepth 2 -type d | grep -v -E 'PAIES|LDM CLARTEO|(20|19){1}[0-9]{2}((0|1){1}[0-9]{1})?$' >> tmpDirectoriesP2.adfp
	fi
done

echo "2"

cat tmpDirectoriesP2.adfp >> tmpDirectoriesP.adfp
cat tmpDirectoriesP.adfp > abnormalDirectoriesP.adfp


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
	name=$(basename "`head -$j abnormalDirectoriesP.adfp  | tail -1`")
	if [ `echo $name | grep -E '^[0-9]{5,7}(A|B|C)?' | wc -l` -eq 1 ]
	then
		echo $name >> abnormalDirectoriesN.adfp
	fi
done


echo "phase 2"

find . -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' currentClientDirectory1;
do
	if [ `echo "${currentClientDirectory1}" | grep -E '^./[0-9]{5,7}(A|B|C)?' | wc -l` -eq 1 ]
	then
		nom=`basename "${currentClientDirectory1}"`
		echo "${nom}" >> nomClients.adfp
	fi
done
echo "phase 3"

echo "phase 4"

for currentAnormalDirectory in `cat abnormalDirectoriesN.adfp`
do

	if [ `grep $currentAnormalDirectory nomClients.adfp | wc -l` -gt 0 ]
	then
		printf "\t Dossiers multiples trouvés $currentAnormalDirectory\n"
		echo "$currentAnormalDirectory" >> fichierDoubles.adfp
	fi

done


echo "phase 5"


for fichier in `cat fichierDoubles.adfp`
do
	if [ `cat abnormalDirectoriesP.adfp | grep -E ^./"$fichier"$ | wc -l` -eq 0 ]
	then
		echo "./$fichier" >> abnormalDirectoriesP.adfp
		echo "$fichier" >> abnormalDirectoriesN.adfp
	fi
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
	if [ `find "${n}" -mindepth 1 -maxdepth 1 -type d |	grep -v -E 'PAIES|LDM CLARTEO|(20|19)[0-9]{2}((0|1){1}[0-9]{1})?$' | wc -l` -eq 0 ]
	then
		echo "${n}" >> correctSingleClientDirectoryWithNoContentP.adfp
	else
		echo "${n}" >> correctSingleClientDirectoryWithContentP.adfp
	fi
done

# -------------------------- creation du fichier log ---------------------------

diagnosticFile=anomaly-diagnostic-file-$dateOfTheDay

touch $diagnosticFile


printf "\n------------------------------------------------------------------------\nDossiers ayant plusieurs occurrences :\n" >> $diagnosticFile
cat multipleDirectoriesP.adfp >> $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom invalide ayant une seule occurrence :\n" >> $diagnosticFile
cat noncorrectSingleClientDirectoryP.adfp >> $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom valide ayant une seule occurrence :\n" >> $diagnosticFile
cat correctSingleClientDirectoryWithContentP.adfp >> $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom valide, ayant une seule occurrence, ne comportant pas de dossiers anormaux :\n" >> $diagnosticFile
cat correctSingleClientDirectoryWithNoContentP.adfp >> $diagnosticFile

# printf "\n------------------------------------------------------------------------\ndossier à la racine non valide\n" >> $diagnosticFile

# find . -mindepth 1 -maxdepth 1 -type d | grep -v -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C)?$' >> $diagnosticFile

rm -r *.adfp

printf "Diagnostic des anomalies terminé\n"
