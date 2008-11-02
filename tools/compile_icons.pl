#!/usr/bin/perl

############################################################################
#
# This script Converts and merges icons.
# This is used to get as many Icons as possible.
# So if you have a convertable Icon you have the chance to get icons 
# for all other themes too.
# merge-icons-all-from-svg2classic2square
# Convert and merge icons for the map
# so we merge between different themes to have more icons
#
#############################################################################

#use diagnostics;
use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;
use Getopt::Long;
use IO::File;
use Image::Info;
use Image::Magick;
use Pod::Usage;
use XML::Simple;
#use utf8;

# Set defaults and get options from command line
my ($man,$help,$DEBUG,$VERBOSE)=(0,0,0,0);
#my $src_dir="./build";
my $dst_dir="./build";
Getopt::Long::Configure('no_ignore_case');
GetOptions ( 
#    'src-dir'            => \$src_dir,
    'dst-dir'            => \$dst_dir,
    'd+'                 => \$DEBUG,
    'debug+'             => \$DEBUG,      
    'verbose'            => \$VERBOSE,
    'v+'                 => \$VERBOSE,
    'h|help|x'           => \$help, 
    'MAN'                => \$man, 
    'man'                => \$man, 
    )
    or pod2usage(1);

pod2usage(1) if $help;
pod2usage(-verbose=>2) if $man;

# --------------------------------------------
# Create a path for a given Filename
sub mkpath4icon($) {
    my $filename = shift;
    my $dir = dirname($filename);
    if ( ! -d $dir ) {
	mkpath($dir) || warn ("Cannot create Directory: '$dir'");
    };
	     };



# --------------------------------------------
# Resize Image to $size x $size
sub image_resize($$$){
    my $src_file = shift;
    my $dst_file = shift;
    my $size = shift;
    print "	resize $src_file	-scale ${size}x${size} $dst_file\n";

    eval { # in case image::magic dies
	my $image = Image::Magick->new(); # size => "${size}x${size}");
	my $rc = $image->Read($src_file);
	warn "$rc" if "$rc";
	$rc = $image->Sample(geometry => "${size}x${size}+0+0");
	
	$rc = $image->Transparent(color=>"white");
	warn "ERROR: $rc" if "$rc";


	$image->Comment("Converted from $src_file");

	mkpath4icon($dst_file);
	$rc = $image->Write($dst_file);
	warn "ERROR: $rc" if "$rc";
    };
    warn "ERROR: $@" if $@;
}

# --------------------------------------------
my $conv_string="Converted from http://svn.openstreetmap.org/applications/share/map-icons";
my ($src_theme,$dst_theme);

print "Merging in directory '$dst_dir'";
print "\n";

($src_theme,$dst_theme)=qw(svg-png classic.big);
print "$src_theme	-->	$dst_theme\n";
for my $src ( 
    split(/\s+/,
	  `find "$dst_dir/$src_theme/" -name "*.png" | grep -v incomming` ) ) {
    my $dst = "$src";
    $dst =~ s/svg-png/classic.big/;
#    $DEBUG && print STDERR "check $src	$dst\n";
    next unless -s $src;
    next if -s $dst;
    $DEBUG && print "copy($src,$dst)\n";
    copy($src,$dst);
}

($src_theme,$dst_theme)=qw(svg-twotone-png classic.big);
print "$src_theme	-->	$dst_theme\n";
for my $src ( 
    split(/\s+/,
	  `find "$dst_dir/$src_theme/" -name "*.png" | grep -v incomming`)) {
    my $dst = "$src";
    $dst =~ s/svg-png/classic.big/;
    next unless -s $src;
    next if -s $dst;
    mkpath4icon($dst);
    $DEBUG && print "copy($src,$dst)\n";
    copy("$src","$dst");
}

($src_theme,$dst_theme)=qw(classic.big classic.small);
print "$src_theme	-->	$dst_theme\n";
for my $src ( 
    split(/\s+/,
	  `find "$dst_dir/$src_theme/" -name "*.png" | grep -v incomming` ) ) {
    my $dst = "$src";
    $dst =~ s/classic.big/classic.small/;
    next unless -s $src;
    next if -s $dst;
    image_resize($src,$dst,16);
# -comment "Converted from classic.big"
}

($src_theme,$dst_theme)=qw(classic.small classic.big);
print "$src_theme	-->	$dst_theme\n";
for my $src ( 
    split(/\s+/,
	  `find "$dst_dir/$src_theme/" -name "*.png" | grep -v incomming` ) ) {
    my $dst = "$src";
    $dst =~ s/classic.small/classic.big/;
    next unless -s $src;
    next if -s $dst;
    print "	convert $src	-scale 32x32 $dst\n";
    image_resize($src,$dst,32);
# -comment "${conv_string}/classic.small"
}

($src_theme,$dst_theme)=qw(classic.big square.big);
print "$src_theme	-->	$dst_theme\n";
for my $full_path (
    split(/\s+/,
	  `find "$dst_dir/$src_theme/" -name "*.png" | grep -v -e incomming -e empty.png` ) ) {
    # merge and convert an image from classic.big to square.big
    my $src=${full_path};
    $src=~ s/square.big/classic.big/;
    my ($src_theme) = ( $src =~ m,[^/]+,);
    my $dst_theme="square.big";
    my $dir=dirname($src);
    $dir=basename($dir);
    my $dst="$dst_dir/$dst_theme/" . basename($src);

    next unless -s $src;
    next if -s $dst;

    $DEBUG && print "Try to create $src	========> $dst\n";


    my $empty="$dst_dir/$dst_theme/$dir/empty.png";
    $DEBUG && print "checking '$empty'\n";
    if ( ! -s $empty ) {
	my $empty=dirname($empty);
    $empty=dirname( $empty)."/empty.png";
	$DEBUG && print "checking '$empty'\n";
    }
    if ( ! -s $empty ) {
	$empty=dirname($empty);
	$empty=dirname($empty)."/empty.png";
	$DEBUG && print "checking '$empty'\n";
    }
    if ( ! -s $empty ) {
	$empty=dirname($empty);
	$empty=dirname($empty)."/empty.png";
	$DEBUG && print "checking '$empty'\n";
    }
	if ( ! -s $empty ) {
	print "empty 2 $empty missing for $src\n";
	print "missing\n";
	next;
    }

	#print "check for merging: $src_theme --> $dst_theme	$dst\n";
    if ( ! -s $empty ) {
	print "Empty missing\n";
	next;
    }
    print "	converting/merging: $src --> $dst\n";
    image_resize($src,'/tmp/reduced.png',25);
    mkpath4icon($dst);
    `convert $empty -geometry +4+4 /tmp/reduced.png  -composite $dst`;
#  -comment "${conv_string}/classic.big" 
#    print "Converted $src $dst\n";
}

($src_theme,$dst_theme)=qw(square.big square.small);
print "$src_theme	-->	$dst_theme\n";
for my $src ( 
    split(/\s+/,
	  `find "$dst_dir/$src_theme/"  -name "*.png" | grep -v incomming` ) ) {
    my $dst = "$src";
    $dst =~ s/square.big/square.small/;
    next unless -s $src;
    next if -s $dst;
    mkpath4icon($dst);
    print "	convert $src	-scale 16x16 $dst\n";
    image_resize($src,$dst,16);
    #  -comment "$conv_string/square.big"
}

print "Merging icons across Themes complete\n";


# =item B<--src-dir>
# The Source Directory. Default is ./


__END__

=head1 NAME

B<compile_icons.pl> Version 0.1

=head1 DESCRIPTION

B<compile_icons.pl>  Convert/merges icons
This is used to get as many Icons as possible.
So if you have a convertable Icon you have the chance to get icons 
for all other themes too.

=head1 SYNOPSIS

B<Common usages:>

compile_icons.pl [-d] [-h] [--man] <build-directory>

=over

=item B<--dst-dir>

The Destination Directory. Default is ./build/

=item B<--man>

Print this small usage

=item B<-h>

Print small Help

=item B<-d>

Add some more Debug Output

=back
