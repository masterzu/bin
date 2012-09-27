#!/bin/bash

# split SQL script with CREATE TABLE

# * Fri Mar  2 16:02:25 CET 2012
# - BUGFIX : replace ' to \' in some case:
#            when not ,' or ',
# - CHANGE: add DROP TABLE 'TABLENAME'; before then CREATE TABLE

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
# affiche une chaine au format ${FILEINBASE}_SPLIT_00${1}_${2}_${FILEINBASE}.sql
itofile() {
	printf '%s_SPLIT_%.3d_%s.sql' "$FILEINBASE" "$1" "$2"
}

trap_user() {
	echo
	echo "Interupted by user : clean file $TEMPFILE"
	rm -f $TEMPFILE
	exit
}

function do_debug() {
    echo -en "\033[0;31m[debug\033[1;33m: $@\033[0;31m]\033[00m"
}
# Main ####################################################
readonly TEMPFILE=$(mktemp)
i=0
no=1
fileout=$(itofile $i)


trap trap_user INT TERM

echo -n "Beginning "

while read line
do

    # FIXME dirty hack for \ character

    test -n "$line" && {
        do_debug "old line: $line"
        echo "$line" | grep -q '\\' && {
            do_debug "[find a \\ line $no]"
            line2=$(echo "$line" | sed 's_\_\\_g')
            line="$line2"
            do_debug "new line: $line"
        } || do_debug "no \\ found"
    }


    
	#echo " : $line"
	if echo "$line" | egrep -q '^CREATE TABLE `'
	then
		table=$(echo "$line" | awk -F '`' '{print $2}')
		test -n "$table" || { echo; echo "E: cant find table name"; exit; }

        echo
		echo " write to $fileout"
        mv "$TEMPFILE" "$fileout"
		echo
        : > $TEMPFILE

		(( i++ ))
		echo -n "New table \`$table\` "
		fileout=$(itofile $i $table)
        echo "-- HACK from PCHT : add drop before create" >> $TEMPFILE
        echo "DROP TABLE \`${table}\`;" >> $TEMPFILE
        echo "" >> $TEMPFILE

        echo "$line" >> $TEMPFILE
        
		#echo "New file : $fileout "
		echo -n '.'
	else
		echo -n '.'
        echo "$line" >> $TEMPFILE
	fi
    (( no++ ))

done < "$FILEIN"
echo
echo " write final table to $fileout"
mv "$TEMPFILE" "$fileout"

