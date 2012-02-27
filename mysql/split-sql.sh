#!/bin/bash

# split SQL script with CREATE TABLE

usage() {
cat <<EOT
$(basename $0) FILE.SQL

split FILE.SQL to NNN-table.sql
EOT
}

# Arguments ###############################################

test $# != 1 && { echo "E: FILE.SQL must be set"; usage; exit; }

readonly FILEIN="$1"

# Functions ###############################################

readonly FILEINBASE="${FILEIN%.*}"
# affiche un entier de format ${FILEINBASE}_SPLIT_00${1}_${2}_${FILEINBASE}.sql
itofile() {
	printf '%s_SPLIT_%.3d_%s.sql' "$FILEINBASE" "$1" "$2"
}

trap_user() {
	echo
	echo "Interupted by user : clean file $TEMPFILE"
	rm -f $TEMPFILE
	exit
}

# Main ####################################################
readonly TEMPFILE=$(mktemp)
i=0
no=1
fileout=$(itofile $i)


trap trap_user INT TERM

echo "Initial file $fileout"

while read line
do

    # FIXME dirty hack for \ character
    echo "$line" | grep -q '\\' && {
        echo -n "[find a \\ line $no]"
        line2=$(echo "$line" | sed 's_\\_\\\\_g')
        line="$line2"
        #echo new line: $line
    }

    
	#echo " : $line"
	if echo "$line" | egrep -q '^CREATE TABLE `'
	then
		table=$(echo "$line" | awk -F '`' '{print $2}')
		test -n "$table" || { echo; echo "E: cant find table name"; exit; }

		echo " write to $fileout"
		#-- echo -e "$buff" > $fileout
        mv "$TEMPFILE" "$fileout"
		echo
		echo "Find new table : $table"
        : > $TEMPFILE

		(( i++ ))
		fileout=$(itofile $i $table)
		#-- buff="$line"
        echo "$line" >> $TEMPFILE
        
		echo -n " + write new table to $fileout"
		echo -n '.'
	else
		echo -n '.'
		#-- buff="$buff\n$line"
        echo "$line" >> $TEMPFILE
	fi
    (( no++ ))

done < "$FILEIN"
echo " write final table to $fileout"
#-- echo -e "$buff" > $fileout
mv "$TEMPFILE" "$fileout"

