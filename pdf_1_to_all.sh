#!/bin/bash
# 
# blabla
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=1
# History
# * 06 Feb 2013 - 1
# - initial version
 
function usage() {
cat <<EOT
Usage: $(basename $0) [-hnvVdn] <final PDF file> <PDF file1> <PDF file2> ...

Get the first page of each PDF file and concat to a new one

Options:
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
 
function do_crit () { cal=`caller 0`;echo "E: (line: $cal) $@" >&2; exit 1;  }
#do_crit This is an critical error
 
function do_err () { echo "E: $@" >&2; exit 1;  }
#do_err This is an error test
 
function do_err_usage () { echo "E: $@" >&2; usage; exit 1;  }
#do_err_usage This is an error with usage
 
function do_warn () { echo "W: $@";  }
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

## Arguments ##############################################

OPTIND=1
while getopts hnvVdq opt ; do
   case "$opt" in
        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 
test $# -gt 1 || do_err_usage Missing argument

FILEOUT="$1"

test -n "$FILEOUT" || do_err_usage Argument 1 must be NON EMPTY
test -f $FILEOUT && do_err "File $FILEOUT already exists. Abort"

shift

# warning: use "$@" to preserve spaces in file names
#for f in "$@"; do echo "|$f|"; done

gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dFirstPage=1 -dLastPage=1 -sOutputFile="$FILEOUT" "$@"


# Main ####################################################

#trap do_trap_user TERM INT
#trap do_trap_exit EXIT



# vim:set ts=4 sw=4 sta ai spelllang=en:

