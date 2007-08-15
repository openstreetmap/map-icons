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
    # Create directories
    find  $dir -type d | grep -v '/\.svn/' | \
    while read nd ; do 
	mkdir -p $dst/$nd 
    done 

    # Copy Files
    find $dir -name "*.svg" -o -name "*.png" | grep -v "/.svn/" | \
    while read fn ; do 
	cp -p $fn $dst/$fn
    done 
done

