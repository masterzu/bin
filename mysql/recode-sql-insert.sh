#!/bin/bash
# 
# re-encode les champs des INSERT en LATIN1 > UTF8 ou UTF8 > LATIN1
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=2
# History
# * Thu Mar  1 16:14:46 CET 2012
# - BUGFIXs
# * 24 Feb 2012 - 1
# - initial version

 

function usage() {
cat <<EOT
Usage: $(basename $0) [-hnvVdna] <file> [ <field> *]
Print / recode insert statement of SQL file <file>.
<fields> are integers

Options:
    -a : automatic mode, scan and change 

    -h : print this page
    -V : print version
    -v : verbose -- conflict with -q
    -q : quiet -- conflict with -v
    -n : test mode ; do not write on disk

EOT
}

## Functions ##############################################

function do_debug () { [ $DEBUG ] && echo "[debug] $@" >&2 || false; }
#do_debug bla bla in debug
#do_debug mode debug || echo mode not debug
 
function do_err () { cal=`caller 0`;echo "E: (line: $cal) $@" >&2; exit 1;  }
#do_err This is an error test
 
function do_warn () { echo "E: $@";  }
#do_warn This is an error test
 
function do_print () { [ -z $QUIET ] && echo "$@"; }
#do_print this is a test
 
function do_printf () { [ -z $QUIET ] && printf "$@"; }
#do_printf "%10s_%20s_%-10s_%s\n" this is a test


function do_verbose () { [ -n "$VERBOSE" ] && echo "$@"; }

function do_test () { [ -n "$TEST" ] && { [ -n "$*" ] && echo "[test] $@" || true; }  || false; }
#do_test echo test || echo mode production
#do_test || echo mode production2

function do_log() { [ -n "$LOG" ] && echo "$@" | tee -a "$LOG"; }

function do_trap_user() { echo "Interuption by user"; }
function do_trap_exit() { echo "exit prout"; }



# test if split have to be done : ie line ~= /^INSERT/ 
# FIXME and char Ã present
function must_split() {
    local line="$1"
    test -n "$line" || return 0
    echo "$line" | egrep -q '^INSERT' || return 1
    echo "$line" | grep -q 'Ã' && return 0 || return 1
}

# test if recode have to be done : FIXME char Ã present
function must_recode() {
    local line="$1"
    test -n "$line" || return 1
    echo "$line" | grep -q 'Ã' \
        && { do_debug '[must_recode] = True'; return 0; } \
        || { do_debug '[must_recode] = False'; return 1; }
}

# clean and split an INSERT SQL line to list space separated
# print the modified line
function split() {
    local line="$1"
    test -n "$line" || return
    echo "$line" | egrep -q '^INSERT' || { echo -n "$line"; return; }
    # W: use NOT greeding version of .* : .+?
    do_debug "[split] l : $line"
    local l1=$(echo "$line" | perl -pe 's/^.+?\((.*)\).+?$/\1/')
    do_debug "[split] l1: $l1"
    local line2=$(echo $l1|sed 's/,/ /g')
    do_debug "[split] = $line2"
    echo $line2
}

# join a line with a string
function join() {
    local sep="$1"
    shift
    local resu=''
    for i in $@
    do
        resu="${resu}${sep}$i"
    done
    
    resu=${resu:${#sep}}
    do_debug "join($sep, $@) = $resu"
    echo $resu
}


# print the beginnig of a split
function begin_split() {
    local line="$1"
    test -n "$line" || return
    echo "$line" | egrep -q '^INSERT' || { return; }
    local l=$(echo $(echo $line|sed 's/(.*$/(/'))
    do_debug "[begin_split] = $l"
    echo "$l"
}

# print the endding of a split
function end_split() {
    local line="$1"
    test -n "$line" || return
    echo "$line" | egrep -q '^INSERT' || { return; }
    local l=$(echo $(echo $line|sed 's/^.*)/)/'))
    do_debug "[end_split] = $l"
    echo "$l"

}

# print one arguments per line
function one_per_line() {
    for i
    do 
        echo "$i"
    done
}

function uniq_sorted_line() {
    local idxs="$(one_per_line $@ | sort | uniq)"
    echo "$idxs"
}
   
function is_in() {
    local item="$1"
    shift
    local list="$@"
    test -z "$item" -o -z "$list" && return 0
    for i in $list
    do
        test $i == $item && return 0
    done
    return 1
}
#is_in 1 "4 2 1 5 7 1" && echo OK || echo FAILED
#is_in 1 4 2 1 5 7 1 && echo OK || echo FAILED
#is_in 1 "4 2 11 5 7 10" && echo FAILED || echo OK
#is_in 1 4 2 11 5 7 10 && echo FAILED || echo OK

## Arguments ##############################################

OPTIND=1
while getopts hnvVdqa opt ; do
   case "$opt" in
        #o) FILEOUT="$OPTARG";;
        a) AUTO=1;;

        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))

test $# == 0 && { usage; exit; } 

if test $# -lt 1
then
    do_warn Missing argument
    usage
    exit
fi

readonly FILEIN="$1"
test -f "$FILEIN" || { do_warn "File \`$FILEIN' dont exists"; exit; }

shift 1

test $# != 0 -a "$AUTO" == 1 && {
    do_warn "-a and set parameters FIELDS mutual exclusive"
    usage
    exit
}

readonly LOG="$(basename $0).log"

# Main ####################################################

#trap do_trap_user TERM INT
#trap do_trap_exit EXIT

if test $# == 0 -o "$AUTO" == 1
then
    ### mode print
    list_indexes=''
    list_items=''
    file_changed=0
    do_log "### [$(date)] scan \`$FILEIN' started"
    while read line
    do
        do_debug "######" $line
        #begin=$(begin_split "$line")
        liste=$(split "$line")
        #end=$(end_split "$line")
        if must_split "$line"
        then
            do_debug $liste
            i=1
            for item in $liste
            do
                if must_recode "$item" 
                then
                    do_verbose "Item $i must be recoded (\`$item')"
                    list_indexes="${list_indexes} $i"
                    list_items="$list_items $item"
                    file_changed=1
                else
                    do_debug "item \`$item' clean"
                fi
                (( i++ ))
            done

        else
            do_debug 'line dont be splitter'
        fi
        echo -n .
    done < "$FILEIN"
    echo
    do_log "### [$(date)] scan \`$FILEIN' finished"
    items=$(uniq_sorted_line $list_items)
    idxs=$(uniq_sorted_line $list_indexes)
    test "$file_changed" != 1 && {
        echo "File seems good"
        #file "$FILEIN"
        exit
    }
    test "$AUTO" != 1 && {
        echo
        echo "Items :"
        echo "$items"
        echo
        echo "Command to recode:"
        echo "\$ $0 $FILEIN $idxs"
        exit
    }
fi

if test $# != 0 -o "$AUTO" == 1
then
    ### mode set
    FIELDS="${@-$idxs}"
    #echo "set with items $FIELDS"

    tempfile=$(mktemp)
    file_changed=0
    do_log "### [$(date)] recode \`$FILEIN' started"
    while read line
    do
        do_debug "### $line"
        if must_split "$line"
        then
            begin=$(begin_split "$line")
            middle=$(split "$line")
            end=$(end_split "$line")
            middle2=''
            middle_changed=0
            i=1
            for item in $middle
            do

                if must_recode "$item" && is_in $i $FIELDS
                then
                    file_changed=1
                    middle_changed=1
                    # retro-encode utf8>>latin1
                    item2=$(echo "$item" | iconv -f UTF8 -t LATIN1)
                    do_log "recode \`$item' >> \`$item2'"
                    middle2="${middle2} ${item2}"
                else
                    middle2="${middle2} ${item}"
                fi
                (( i++ ))
            done
            if test "$middle_changed" == 1
            then
                line="${begin}$(join ',' ${middle2})${end}" 
                #echo "$line" >> $tempfile
                
            else
                :
                #echo "$line" >> $tempfile
            fi

        else
            :
            #echo "$line" >> $tempfile
        fi
        echo "$line" >> $tempfile || do_err "Cant wappend on $tempfile"

    done < $FILEIN

    do_log "### [$(date)] recode \`$FILEIN' finished"
    echo
    if test $file_changed == 1
    then
        FILEGZ="${FILEIN}.gz"
        test -f "$FILEGZ" && {
            do_verbose "Archive file \`$FILEGZ' found. Dont touch it."
        } || {
            do_log "Save file \`$FILEIN' to archive \`$FILEGZ'"
            set -e
            gzip -c "$FILEIN" > "$FILEGZ"
            set +e
        }
       

        mv -f "$tempfile" "$FILEIN" || { do_log "Cant create file \`$FILEIN'"; exit 1; }
        echo "File \`$FILEIN' changed"

        
    else
        diff -q "$FILEIN" "$tempfile" || exit 1
        echo "File $FILEIN not changed"
    fi
fi



# vim:set ts=4 sw=4 sta ai spelllang=en:

