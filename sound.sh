
#OPTS="-mixer /dev/mixer -mixer-channel Master -ao alsa"
OPTS=""
SOUNDDIR="$(dirname $0)/sounds"
SOUND=$(basename $0 .sh)

SOUND=$SOUNDDIR/${SOUND#sound_}.mp3
#echo $SOUND

if test ! -f $SOUND; then exit 1; fi

echo mplayer $OPTS $SOUND
mplayer $OPTS $SOUND &
