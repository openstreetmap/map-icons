#!/bin/bash
# Create example for Makefile.am
makefile="Makefile.am"

echo "" >$makefile
for theme in square.big square.small svg japan classic.small classic.big nickw ; do 
    find $theme -type d | grep -v /.svn | while read dir; do
	# if no files in dir
	name=${dir//-/_}
	name=${name//\//_}
	echo "" >>$makefile
	echo -n $name'_DATA =' >>$makefile
	for type in png svg ; do
	    echo $dir/*.$type | grep -q -e '\*' && continue
	    echo -n " $dir/*.$type" >>$makefile
	done
	echo "" >>$makefile
	echo $name'dir = $(datadir)/map-icons/'$dir >>$makefile
    done
    echo  >>$makefile
done

echo  >>$makefile
echo  >>$makefile
echo "EXTRA_DIST= \\" >>$makefile
for theme in square.big square.small svg japan classic.small classic.big nickw ; do 
    find $theme -type d | grep -v /.svn | while read dir; do
	# if no files in dir
	#echo $dir/*.png | grep -q -e '\*' && continue

	name=${dir//-/_}
	name=${name//\//_}
	echo '	$('$name'_DATA)' "\\" >>$makefile
    done
done
echo '	CMakeLists.txt'  "\\">>$makefile
echo '	index.html'  "\\">>$makefile
echo '	overview.de.html'  "\\">>$makefile
echo '	overview.html'  "\\">>$makefile
echo '	README.icons'  "\\">>$makefile
echo '	update_icons.pl'  "\\">>$makefile
echo '	create_makefile.sh' >>$makefile
