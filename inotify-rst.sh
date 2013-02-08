#!/bin/bash
# 
# use inotifywait to autogen HTML from rst files
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=1
# History
# * 13 Feb 2012 - 1
# - initial version
 
function usage() {
cat <<EOT
Usage: $(basename $0) [-hnvVdn] DIR
check and watch for .rst modification files in DIR 

Options:
    -h : print this page
    -V : print version
    -v : verbose -- conflict with -q
    -q : quiet -- conflict with -v
    -n : test mode ; do not write on disk

EOT
}

## Arguments ##############################################

OPTIND=1
while getopts hnvVd opt ; do
   case "$opt" in
        #p) PROUT="$OPTARG";;

        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 
if test $# != 1
then
    echo "W: Missing argument"
    usage
    exit
fi

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

function do_trap_user() { echo "Interuption by user"; }
function do_trap_exit() { echo "exit prout"; }

# Main ####################################################

DIR=${1}

test -d "$1" || do_err "Directory: \`$DIR' dont exists"

cd "$1" && DIR=$(pwd) || do_err "Cant cd to \`$DIR'"
echo "looking at $DIR ..."

inotifywait -m -e MODIFY "$DIR" | while read line; do
    cur_dir=$(echo $line | awk '{print $1}')
    cur_action=$(echo $line | awk '{print $2}')
    cur_file=$(echo $line | awk '{print $3}')
    do_debug "file $cur_file $cur_action in  $cur_dir"

    if echo $cur_file| egrep -q '.rst$'
    then
        file_html="${cur_file%.rst}.html"
        echo "[$(date)] file $file_html must be rebuilded"
        make "$file_html"
    fi
    done

# vim:set ts=4 sw=4 sta ai spelllang=fr:
