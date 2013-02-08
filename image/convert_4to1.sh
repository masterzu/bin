#!/bin/bash
# 
# convert_4to1.sh
# colle 4 images et une, recursivement
#
# operation effectuées:
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

Usage: $(basename $0) [-hnvVdn] [ -r ] ( -t <templ> | <result image> ) <image1> [...]

Operations:
0. check if files are images handled
1. rotate <imageN> verticaly if needed
2. append it left-right
3. [optional with -r] rotate <result image> verticaly

Options:
    -r : rotate <result image> verticaly
    -t : template for result name as '<templ>-N.png'

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

function is_image() {
    local img="$1"
    local res=$(identify -quiet "$img" 2> /dev/null)
    local r=$?
    do_debug "$img format: $res"
    return $r
}

## Arguments ##############################################

OPTIND=1
while getopts hnvVdqrt: opt ; do
   case "$opt" in
        r) ROTATE=1;;
        t) TEMPLATE="$OPTARG";;

        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))


if test -n "$TEMPLATE"
then
    test $# -lt 1 && do_err_usage Missing argument: need 1 more
    i=1
    while test $i -lt 100
    do
        IMAGEFINALE="${TEMPLATE}-$i.jpg"
        test ! -f "$IMAGEFINALE" && break
        (( i++ ))
    done

    test -f "$IMAGEFINALE" && do_err "no Filename '$TEMPLATE-<n> (n=[1,100])' available; change de template (-t)"
else
    test $# -lt 2 && do_err_usage Missing argument: need 2 more
    IMAGEFINALE="$1"
    shift
    test $# -gt 4 && { do_warn "Il y a plus de 4 fichiers source. Utiliser l'option -t pour definir un <template>"; exit; }
fi

IMAGE1=$1
shift
IMAGE2=${1:-$IMAGE1}; 
shift
IMAGE3=${1:-$IMAGE2}; 
shift
IMAGE4=${1:-$IMAGE3}; 
shift

# Main ####################################################

do_print Processing with $IMAGE1 $IMAGE2 $IMAGE3 $IMAGE4 to $IMAGEFINALE
#touch $IMAGEFINALE
#test $# -gt 0 && exec $0 -t $TEMPLATE $*
#exit

TEMP1=$(tempfile)
TEMP2=$(tempfile)
TEMP3=$(tempfile)
TEMP4=$(tempfile)
TEMP5=$(tempfile)
TEMP6=$(tempfile)
TEMP7=$(tempfile)

test -f "$IMAGEFINALE" && do_err "Final Image '$IMAGEFINALE' already exists"

for i in 1 2 3 4 
do
    eval f="\$IMAGE$i"
    test -f "$f" || do_err "File '$f' dont exists"
done

for i in 1 2 3 4 
do
    eval f="\$IMAGE$i"
    is_image $f || do_err "File '$f' is not an image"
done

trap do_trap_exit EXIT

# rotate image if horizontal
for i in 1 2 3 4 
do
    eval f="\$IMAGE$i"
    eval t="\$TEMP$i"
    do_printf "   rotating/bordering $f ... "; 
    convert $f -rotate '90>' -border 10x10 -bordercolor '#000' -border 5x5 $t && do_print OK || do_err 'rotate error'
    #display $t
done

# append left-right
do_printf "   appending pass1 ... "; 
convert $TEMP1 $TEMP2 +append -rotate '90>' $TEMP5 && do_printf 'pass2 ... ' || do_err 'append error'
convert $TEMP3 $TEMP4 +append -rotate '90>' $TEMP6 && do_printf 'pass3 ... ' || do_err 'append error'
convert $TEMP5 $TEMP6 +append $TEMP7 && do_print OK || do_err 'append error'

# (optional) rotate again
if test -n "$ROTATE" 
then
    do_printf "   rotating and reducing $IMAGEFINALE ... "; 
    convert $TEMP7 -rotate '90>' -resize '25%' $IMAGEFINALE && do_print OK || do_err 'rotate/reduce error'
else
    do_printf "   converting and reducing $IMAGEFINALE ... "; 
    convert $TEMP7 -resize '25%' $IMAGEFINALE && do_print OK || do_err 'reduce error'
fi

# <<recursive>> call

do_print $IMAGEFINALE created
test $# -gt 0 && { do_trap_exit; exec $0 -t $TEMPLATE $*; }

# vim:set ts=4 sw=4 sta ai spelllang=fr:

