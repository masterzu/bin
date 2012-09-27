#! /bin/bash

ENCODER_OPTS="-lavcopts vcodec=mpeg4:acodec=mp2 -of avi -ovc lavc -oac lavc"

input=$1
output=${1}.avi

if [ ! -f "$input" ]; then
    echo "E: missing argument"
    exit 1
fi

if [ -f "$output" ]; then
    echo "output file '$output' already exists! "
    echo "will remove it (Ctrl-C to quit)"
    read
    rm -f "$output"
fi

# test video codecs/tools
if ! mencoder -ovc help|grep -q lavc; then
    echo "E: cant find codec 'lavc'"
    exit 1
fi

echo "# Running :"
echo "mencoder ${ENCODER_OPTS} $input -o $output"
mencoder ${ENCODER_OPTS} $input -o $output
if [ $? != 0 ];then
    echo OK
else
    echo FAILED
fi
