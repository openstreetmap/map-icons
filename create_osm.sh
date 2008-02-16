#!/bin/sh
#
# copy over the icons into an "OSM map features" like hierarchy
#
# the icons are currently sorted in a directory hierarchy that is based on gpsdrive
# this script copies the icons into a hierachy that is much closer to the current "OSM map features" tagging
#
# what you'll need:
# xsltproc from the (cygwin) libxslt package

# go through the directory "themes" we're interested in
for dir in classic.big classic.small square.big square.small svg_png ; do \
	# keep the user informed
	echo +++ $dir +++
	
	# XSLT transformation of JOSM's elemstyles.xml file into a simple shell script
	xsltproc --param src_dir "'$dir'" --param dest_dir "'osm/$dir'" create_osm.xslt ../../editors/josm/core/styles/standard/elemstyles.xml > create_osm.tmp.sh

	# call generated shell script to copy icons into new hierarchy
	./create_osm.tmp.sh
done
