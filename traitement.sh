#!/bin/sh
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

# ----------------------------Traitement des données----------------------------

printf "Traitement des données\n"

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

printf "\n------------------------------------------------------------------------\nDossiers ayant plusieurs occurrences :\n" >> $diagnosticFile
format multipleDirectoriesP.adfp multipleDirectoriesP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom invalide ayant une seule occurrence :\n" >> $diagnosticFile
format noncorrectSingleClientDirectoryP.adfp noncorrectSingleClientDirectoryP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom valide ayant une seule occurrence :\n" >> $diagnosticFile
format correctSingleClientDirectoryWithContentP.adfp correctSingleClientDirectoryWithContentP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\nDossiers avec nom valide, ayant une seule occurrence, ne comportant pas de dossiers anormaux :\n" >> $diagnosticFile
format correctSingleClientDirectoryWithNoContentP.adfp correctSingleClientDirectoryWithNoContentP2.adfp $diagnosticFile

printf "\n------------------------------------------------------------------------\ndossier à la racine non valide\n" >> $diagnosticFile


find . -mindepth 1 -maxdepth 1 -type d | grep -v -E '^(./)?(26|27|84|87){1}[0-9]{4}$|^(./)?(28|88){1}[0-9]{4}(A|B|C)?$' >> badDirectories.adfp
format badDirectories.adfp badDirectories2.adfp $diagnosticFile

#rm -r *.adfp
printf "Diagnostic des anomalies terminé\n"
