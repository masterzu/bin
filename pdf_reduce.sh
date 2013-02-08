#!/bin/bash
# 
# pdf_reduce.sh
# reduce and replace PDF file to A4 for screen
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
VERSION=0.1
# History
# * 16 Apr 2010 - 0.1
# - initial version
 

function usage() {
cat <<EOT
Usage: $(basename $0) [OPTIONS] <source file> <dest file>

reduce and replace PDF file to A4 for screen

    -v : verbose mode
    -h : print this page
    -V : print version

EOT
}

## options
OPTIND=1
while getopts hnvVdq opt ; do
   case "$opt" in
        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TESTING=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 
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

function do_verb () { [ -n "$VERBOSE" ] && echo "$@" || false; }
#do_verb this is a test
#do_verb test2 || echo "not test2"
 
# MAIN ####################################################

if test $# != 2
then
    do_warn Bad argument numbers
    usage
    exit
fi

INPUT="$1"
OUTPUT="$2"

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$OUTPUT" "$INPUT" 2>/dev/null

if test $?
then
    do_debug OK
    do_verb "PDF reduce : '$INPUT' -> '$OUTPUT'"
    do_verb && ls -1hs  "$INPUT" "$OUTPUT" 
else
    do_debug FAILED
    echo Erreur !
fi

exit 0

