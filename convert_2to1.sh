#!/bin/bash
# 
# convert_2to1.sh
# colle 2 images et une
#
# operation efectuées:
# * mettre les image en vertical
# * les coller horizontalement
# * tourner le resultat pour avoir une image verticale
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=1
# History
# * 27 Sep 2012 - 1
# - initial version
 
function usage() {
cat <<EOT

Usage: $(basename $0) [-hnvVdn] [-r ] <image1> <image2> <result image>

Operations:
0. check if files are images handled
1. rotate <image1> and <image2> verticaly if needed
2. append it left-right
3. [optional with -r] rotate <result image> verticaly

Options:
    -r : rotate <result image> verticaly

    -h : print this page
    -V : print version
    -v : verbose -- conflict with -q
    -q : quiet -- conflict with -v
    -n : test mode ; do not write on disk

EOT
}

## Arguments ##############################################

OPTIND=1
while getopts hnvVdqr opt ; do
   case "$opt" in
        r) ROTATE=1;;

        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 

IMAGE1="$1"
IMAGE2="$2"
IMAGEFINALE="$3"

TEMP1=$(tempfile)
TEMP2=$(tempfile)
TEMP3=$(tempfile)

## Functions ##############################################

function do_debug () { [ $DEBUG ] && echo "[debug] $@" >&2 || false; }
#do_debug bla bla in debug
#do_debug mode debug || echo mode not debug
 
function do_err () { echo "E: $@" >&2; exit 1;  }
function do_err_usage () { echo "E: $@" >&2; usage; exit 1;  }
#do_err This is an error test
 
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
function do_trap_exit() { echo "clean temp files ..."; rm -f "$TEMP1" "$TEMP2" "$TEMP3"; }

# Main ####################################################

test $# != 3 && do_err_usage Missing argument

function is_image() {
    local img="$1"
    local res=$(identify -quiet "$img" 2> /dev/null)
    local r=$?
    do_debug "$img format: $res"
    test $r && return 0 || return 1

}

function is_vertical(){
    local img="$1"
    local w=$(identify -format %w "$img")
    local h=$(identify -format %h "$img")
    do_debug "$img format: $w x $h"
    test $h -ge $w && return 0 || return 1


}

test -f "$IMAGE1" || do_err "File '$IMAGE1' dont exists"
test -f "$IMAGE2" || do_err "File '$IMAGE2' dont exists"
test -f "$IMAGEFINALE" && do_err "Final Image '$IMAGEFINALE' already exists"

is_image $IMAGE1 || do_err "File '$IMAGE1' is not an image"
is_image $IMAGE2 || do_err "File '$IMAGE2' is not an image"


trap do_trap_exit EXIT

# rotate image if horizontal
do_printf "rotating $IMAGE1 ... "; 
convert $IMAGE1 -rotate '90>' $TEMP1 && do_print OK || do_err 'rotate error'

do_printf "rotating $IMAGE2 ... "; 
convert $IMAGE2 -rotate '90>' $TEMP2 && do_print OK || do_err 'rotate error'

# append left-right
do_printf "appending ... "; 
convert $TEMP1 $TEMP2 +append $TEMP3 && do_print OK || do_err 'append error'

# (optional) rotate again
if test -n "$ROTATE" 
then
    do_printf "rotating $IMAGEFINALE ... "; 
    convert $TEMP3 -rotate '90>' $IMAGEFINALE && do_print OK || do_err 'rotate error'
else
    cp $TEMP3 $IMAGEFINALE
fi

display $IMAGEFINALE


# vim:set ts=4 sw=4 sta ai spelllang=fr:

