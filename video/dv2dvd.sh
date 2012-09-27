#!/bin/sh

# dvtodvd.sh
# Convert raw DV video to a DVD-compliant VOB file.  Requires mplex from mjpegtools.
# Public domain--share and enjoy!

set -e

# Choose your denoiser--this should probably be made into a command-line option:
DENOISER=yuvdenoise  # best quality, but SLOW
 #DENOISER=hqdn3d      # faster
 #DENOISER=denoise3d   # even faster, but quality suffers

DEINT=""
PROG=""
HALF=""
NOCROP=""
MONO=""
NOSOUND=""
MP2=""
DENOISE=""
VCODEC=mpeg2enc
TVSTD=pal

while [ `echo "x$1" | cut -c1-2` = x- ] ; do
	if [ "x$1" = "x-multi" ] ; then
		MULTI=1
	elif [ "x$1" = "x-deint" ] ; then
		DEINT=1
	elif [ "x$1" = "x-prog" ] ; then
		PROG=1
	elif [ "x$1" = "x-half" ] ; then
		HALF=1
	elif [ "x$1" = "x-nocrop" ] ; then
		NOCROP=1
	elif [ "x$1" = "x-mono" ] ; then
		MONO=1
	elif [ "x$1" = "x-nosound" ] ; then
		NOSOUND=1
	elif [ "x$1" = "x-mp2" ] ; then
		MP2=1
	elif [ "x$1" = "x-denoise" ] ; then
		DENOISE=1
	elif [ "x$1" = "x-ffmpeg" ] ; then
		VCODEC=ffmpeg
	elif [ "x$1" = "x-mpeg2enc" ] ; then
		VCODEC=mpeg2enc
	elif [ "x$1" = "x-ntsc" ] ; then
		TVSTD=ntsc
	elif [ "x$1" = "x-pal" ] ; then
		TVSTD=pal
	else
		echo >&2 "Unknown option: $1"
		echo >&2 "'$0' without parameters for help."
	exit 1
	fi
	shift
done

IN=$1
OUT=$2
VRATE=$3
ARATE=$4
RANGE=$5
if [ "x$ARATE" = x ] ; then ARATE=192 ; fi
v=`echo "x,$VRATE" | cut -d, -f2`

if ! test "x$VRATE" != x -a 0 -lt "$v" -a 0 -lt "$ARATE" 2>/dev/null ; then
	    echo >&2 "Usage: $0 [opts] <infile> <outfile> <video kbps> [<audio kbps> [<start>-<end>]]
Options: -deint    (deinterlace input video)
         -prog     (input video is progressive, i.e. not interlaced)
         -half     (scale video down to half size)
         -nocrop   (do not crop input video to 704x480)
         -mono     (encode audio in mono)
         -nosound  (do not encode audio)
         -mp2      (encode audio in MP2 instead of AC3)
         -denoise  (denoise video)
         -ffmpeg   (use FFmpeg to encode video [default])
         -mpeg2enc (use mpeg2enc to encode video)
         -ntsc     (use NTSC parameters [default])
         -pal      (use PAL parameters)"
exit 1
fi

if [ ! -r "$IN" ] ; then
	echo >&2 "Input file cannot be read!  Aborting."
	exit 1
fi
if [ "x$IN" = "x$OUT" ] ; then
	echo >&2 "Input and output file cannot be the same!  Aborting."
	exit 1
fi
if [ -f "$OUT" ] ; then
	echo >&2 -n "Output file exists; overwrite? [yN] "
	read yn
	if [ "x$yn" != "xY" -a "x$yn" != "xy" ] ; then
	exit 1
	fi
fi

if [ "$MONO" ] ; then
	chan=1
else
	chan=2
fi

rm -f "$OUT".log*
if [ "$VCODEC" = ffmpeg ] ; then
	passes="1 2"
else
	passes=1
fi
if [ "$MP2" ] ; then
	acodec=raw
	N="-N 0x50"
	audext=mp2
else
	acodec=raw
	N=""
	audext=ac3
fi

for pass in $passes ; do
	if [ "$VCODEC" = ffmpeg ] ; then
		F="--export_prof dvd-$TVSTD"
		R="-R $pass,'$OUT.log'"
	else
		F="-F '8,-c -q 2 -4 1 -2 1' --video_max_bitrate 9000"
	fi
	if [ "$NOSOUND" -o \( $pass = 1 -a $VCODEC = ffmpeg \) ] ; then
		x=dv,null
		y=$VCODEC,null
	else
		x=dv,dv
		y=$VCODEC,$acodec
	fi
	if [ "x$RANGE" = x ] ; then
		c=""
	else
		c="-c $RANGE"
	fi
	rm -f "$OUT".m2v.* "$OUT".$audext.*
	if [ "$HALF" ] ; then
		J=""
		if [ "$PROG" ] ; then
			enc="-r 2,2"
		else
			enc="-I 4 -r 1,2"
		fi
		denoise="$DENOISER"
	elif [ "$DEINT" ] ; then
		J="smartdeinter"
		enc=""
		if [ "$DENOISER" = "yuvdenoise" ] ; then
			denoise="yuvdenoise=mode=1"
		else
			denoise="$DENOISER"
		fi
	elif [ "$PROG" ] ; then
		J=""
		enc=""
		denoise="$DENOISER"
	else
		J=""
		enc="--encode_fields b"
		if [ "$DENOISER" = "yuvdenoise" ] ; then
			denoise="yuvdenoise=mode=1"
		else
			denoise="$DENOISER"
		fi
	fi
	if [ "$DENOISE" ] ; then
		if [ "$J" ] ; then J=",$J" ; fi
		J="-J $denoise$J"
	else
		if [ "$J" ] ; then
			J="-J $J"
		fi
	fi
	if [ "$NOCROP" ] ; then
		j=""
	else
		j="-j 0,8,0,8"
	fi
	set -x
	eval 'transcode --ext none,none -i "$IN" -x $x $c -o "$OUT.m2v" -y $y -m "$OUT.$audext" -E 48000,16,$chan '"$F"' $J $N $R -b $ARATE $j -w $VRATE $enc --export_asr 2'
	set +x
	if test -f "$OUT.m2v.m2v" ; then mv -f "$OUT.m2v.m2v" "$OUT.m2v" ; fi
	if test -f "$OUT.$audext.$audext" ; then mv -f "$OUT.$audext.$audext" "$OUT.$audext" ; fi
done

rm -f "$OUT".log

if [ ! "$NOSOUND" ] ; then
	set -x
	mplex -v 1 -f 8 -o "$OUT" -V "$OUT.m2v" "$OUT.$audext"
	set +x
fi

