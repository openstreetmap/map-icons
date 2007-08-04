#!/bin/sh

dst=$1

if [ ! -n "$dst" ] ; then
    echo "Please specify a destination directory"
    echo "Usage:"
    echo "     $0 <destination-dir>"
    exit -1 
fi

mkdir -p $dst
for dir in square.big square.small classic.big classic.small svg svg_tn jp jp_tn ; do \
    find  $dir -type d | grep -v '\.svn' | \
    while read nd ; do 
	mkdir -p $dst/$nd 
    done 

    find $dir -name "*.svg" -o -name "*.png" | \
    while read fn ; do 
	cp $fn $dst/$fn
    done 
done

