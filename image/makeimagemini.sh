#!/bin/bash -e
mkdir mini || exit 
for i in *jpg
do 
    echo $i
    convert -resize 25% $i mini/${i%%.jpg}_.jpg
done
