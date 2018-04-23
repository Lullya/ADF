#!/bin/sh

dicho()
{
	VALUE_TO_FIND=$1
	VALUE_TO_FIND2=${VALUE_TO_FIND:0:6}

	FILE_TO_SEARCH_IN=$2


	count=$(wc -l $FILE_TO_SEARCH_IN | cut -d' ' -f1)
	count=$((($count-1)/2))
	b=0

while :
do

	VALUE_FOUND=$(head -$count $FILE_TO_SEARCH_IN | tail -1)
	VALUE_FOUND=$(echo "$VALUE_FOUND" | awk '$1=$1')

	VALUE_FOUND2=${VALUE_FOUND:0:6}


printf "VALUE_TO_FIND : $VALUE_TO_FIND VALUE_TO_FIND2 : $VALUE_TO_FIND2\n"

printf "VALUE_FOUND : $VALUE_FOUND VALUE_FOUND2 : $VALUE_FOUND2\n"

	if [[ "$VALUE_TO_FIND" == "$VALUE_FOUND" ]]; then
		echo "oui"
		echo "$VALUE_TO_FIND" >> fichierDoubles.adfp
		break
	elif [[ VALUE_TO_FIND2 -eq VALUE_FOUND2 ]]; then
		if [[ $b -eq 3 ]]; then
			echo "value not found"
			break
		else
			"non"
			count=$(($count+1))
			b=$(($b+1))
		fi
	elif [[ VALUE_TO_FIND2 -gt VALUE_FOUND2 ]]; then
		echo "gt"
		count=$(($count+(($count-1)/2)))
	elif [[ VALUE_TO_FIND2 -lt VALUE_FOUND2 ]]; then
		echo "lt"
		count=$(($count-(($count-1)/2)))
	else
		echo "value not found"
		break
	fi

done

}

sort nomClients.adfp > nomClients2.adfp

dicho 282515A nomClients2.adfp
