#! /bin/bash
# resize with $1

if test ! -d mini; then mkdir mini; fi

for i in *jpg
do 
	echo "$i"
	identify -ping $i | awk '{ print "    " $3 " " $7 }'
	echo -n " => "
	if test -f mini/$i
	then
		echo "(already exists)"
		echo -n "    "
	else
		convert $i -resize 25% mini/$i
	fi
	#echo -n "   mini/$i : "
	identify -ping "mini/$i" | awk '{ print $3 " " $7 }'
done

