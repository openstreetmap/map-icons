#!/bin/sh


dst=$1

if [ ! -n "$dst" ] ; then
    echo "Please specify a irectory to work in"
    echo "Usage:"
    echo "     $0 <working-dir>"
    exit -1 
fi


# merge-icons-all-from-svg2classic2square
# Convert and merge icons for the map
# so we merge between different themes to have more icons

cd $dst

echo "Merging in directory `pwd`"
echo ""
echo "svg_tn --> classic.big"
find svg_tn/ -name "*.png" | grep -v incomming | while read src ; do 
    dst=${src/svg_tn/classic.big}
    test -s $src || continue
    test -s $dst && continue
    mkdir -p `dirname $dst`
    cp $src $dst
done

echo "classic.big --> classic.small"
find classic.big/ -name "*.png" | grep -v incomming | while read src ; do 
    dst=${src/classic.big/classic.small}
    test -s $src || continue
    test -s $dst && continue
    mkdir -p `dirname $dst`
    echo "convert $src	-scale 16x16 $dst"
    convert $src -scale 16x16 $dst
done

echo "classic.small --> classic.big"
find classic.small/ -name "*.png" | grep -v incomming | while read src ; do 
    dst=${src/classic.small/classic.big}
    test -s $src || continue
    test -s $dst && continue
    mkdir -p `dirname $dst`
    echo "convert $src	-scale 32x32 $dst"
    convert $src -scale 32x32 $dst
done

echo "classic.big --> square.big"
find classic.big/ -name "*.png" | grep -v -e incomming -e empty.png | \
    while read full_path ; do 
    # mergeand convert an image from classic.big to square.big
    src=${full_path#square.big#classic.big}
    src_theme=${src%/*}
    dst_theme=square.big
    dir=`dirname $src`
    dir=${dir#*/}
    dst=$dst_theme/${src#*/}

    #echo "Check $src $dst"

    test -s $dst && continue
    test -s $src || continue

    empty=$dst_theme/$dir/empty.png
    if [ ! -s $empty ]; then 
	empty="`dirname $empty`"
	empty="`dirname $empty`/empty.png"
    fi
    if [ ! -s $empty ]; then 
	empty="`dirname $empty`"
	empty="`dirname $empty`/empty.png"
    fi
    if ! [ -s $empty ] ; then
	echo "empty 2 $empty missing for $src"
	echo "missing"
	continue
    fi

	#echo "check for merging: $src_theme --> $dst_theme	$dst"
    if ! [ -s $empty ] ; then
	echo "Empty missing"
	continue
    fi
    echo "converting/merging: $src --> $dst"
    convert $src	-scale 25x25 /tmp/reduced.png
    mkdir -p `dirname $dst`
    convert $empty \
	-geometry +4+4 /tmp/reduced.png  \
	-composite $dst
#    echo "Converted $src $dst"
done

echo "square.big --> square.small"
find square.big/ -name "*.png" | grep -v incomming | while read src ; do 
    dst=${src/square.big/square.small}
    test -s $src || continue
    test -s $dst && continue
    mkdir -p `dirname $dst`
    echo "convert $src	-scale 16x16 $dst"
    convert $src -scale 16x16 $dst
done

echo "Merging complete"