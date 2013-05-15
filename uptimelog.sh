#!/bin/bash
# 
# cron script to remember the best uptime on a computer
 
# Patrick CAO HUU THIEN <patrick.cao_huu_thien@upmc.fr>
# 
readonly VERSION=1
# History
# * 15 May 2013 - 1
# - initial version
 

function usage() {
cat <<EOT
Usage: $(basename $0) [ -q ]

crontab script to save best uptime in $HOME/.uptime-<date>

print new record in human readable format

options:
    -q : no output

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
        p) PROUT="$OPTARG";;

        h) usage; exit;;
        v) VERBOSE=1;;
        d) DEBUG=1;;
        q) QUIET=1;;
        n) TEST=1;;
        V) echo "$(basename $0) - $VERSION"; exit;;
   esac
done
shift $(($OPTIND - 1))
 
test $# == 0 || do_err_usage Missing argument

# Main ####################################################

#trap do_trap_user TERM INT
#trap do_trap_exit EXIT

FILEBASE="$HOME/.uptime"
TD=$HOME/bin/td.sh

test -f $TD || { echo "E: Cant find $TD. Try https://github.com/livibetter/td.sh/blob/master/td.sh"; exit 1; }

current_uptime=$(cat /proc/uptime|awk '{print $1}'|awk -F. '{print $1}' || { echo "E: Cant use /proc/uptime!!"; exit 1; } )
old_uptime=$(cat $FILEBASE 2>/dev/null|| echo 0)


(( $current_uptime >= $old_uptime )) && {
    do_print "New uptime record :) $($TD $(echo $current_uptime)) "
    echo $current_uptime > $FILEBASE
} || {
    do_print "reboot ;( Reset uptime records."
    old_uptime_date=$(stat -c %y $FILEBASE|awk '{print $1}' 2>/dev/null || date +%Y-%m-%d)
    mv $FILEBASE "$FILEBASE-$old_uptime_date"
    

}




# vim:set ts=4 sw=4 sta ai spelllang=en:

