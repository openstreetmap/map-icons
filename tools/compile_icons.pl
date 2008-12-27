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

# TODO replace the `find` Command


#use diagnostics;
use strict;
use warnings;

#use utf8;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;
use File::Slurp;
use Getopt::Long;
use IO::File;
use Image::Info;
use Image::Magick;
use Pod::Usage;
use XML::Simple;
use File::stat;

# Set defaults and get options from command line
my ($man,$help,$DEBUG,$VERBOSE)=(0,0,0,0);
my ( $do_copy_from_source,$do_update_thumbnails,$do_merge_icons)=(0,0,0);
my $src_dir=".";
my $dst_dir="./build";
Getopt::Long::Configure('no_ignore_case');
GetOptions ( 
    'src-dir:s'          => \$src_dir,
    'dst-dir:s'          => \$dst_dir,
    'copy-from-source'   => \$do_copy_from_source,
    'update-thumbnails'  => \$do_update_thumbnails,
    'merge-icons'        => \$do_merge_icons,
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

( $do_copy_from_source,$do_update_thumbnails,$do_merge_icons)=(1,1,1) 
    unless $do_copy_from_source || $do_update_thumbnails || $do_merge_icons;

sub update_svg_thumbnail($$);

# --------------------------------------------
# Check if dst needs to be updated from src
# Params (SRC,DST)
sub needs_update($$){
    my $src_file = shift;
    my $dst_file = shift;
    warn "$src_file not existing, but i'm asked to check if we need to update from it.\n"
	unless -s $src_file;
    return 1 unless -s $dst_file;
    my $time_src = (stat($src_file)->mtime);
    my $time_dst = (stat($dst_file)->mtime);
    return 0 if $time_src < $time_dst;
    return 1;
}


# --------------------------------------------
sub create_png();
our $COUNT_FILES_SEEN=0;
our $COUNT_FILES_CONVERTED=0;
my @theme_dirs=qw(classic.big classic.small 
		  square.big square.small
		  svg
                  svg-twotone
		  japan
		  nickw
		  );


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
    print "	resize $src_file	-scale ${size}x${size} $dst_file\n" 
	if $VERBOSE || $DEBUG ;

    eval { # in case image::magic dies
	my $image = Image::Magick->new(); # size => "${size}x${size}");
	my $rc = $image->Read($src_file);
	warn "!!!WARNING: Load Image: $rc" if "$rc";
	$rc = $image->Sample(geometry => "${size}x${size}+0+0");
	
	$rc = $image->Transparent(color=>"white");
	warn "!!!!!! ERROR: $rc" if "$rc";


	$image->Comment("Converted from $src_file");

	mkpath4icon($dst_file);
	$rc = $image->Write($dst_file);
	warn "!!!!!! ERROR: $rc" if "$rc";
	};
    warn "!!!!!! ERROR: $@" if $@;
	     }



# --------------------------------------------
# Take the template and merge src on top of it in the middle
sub image_merge($$$){
    my $template_file = shift;
    my $src_file = shift;
    my $dst_file = shift;
    print "	merge $src_file with $template_file  ---> $dst_file\n"
	if $VERBOSE || $DEBUG;

    my $size=28;

    eval { # in case image::magic dies
	my $image = Image::Magick->new(); # size => "${size}x${size}");
	my $rc = $image->Read($template_file);
	warn "!!!WARNING: Load Image: $rc" if "$rc";

	my $image1 = Image::Magick->new(); # size => "${size}x${size}");
	$rc = $image1->Read($src_file);
	warn "!!!WARNING: Load Image: $rc" if "$rc";
	my $image_size = $image1->Get('size');
	print "Size: '$image_size'\n";
	$rc = $image1->Sample( geometry => "${size}x${size}+0+0" );
	$rc = $image1->Transparent(color=>"white" );
	warn "!!!!!! ERROR: $rc" if "$rc";

	$rc = $image->Composite( compose  => 'Overlay', 
				 geometry => '${size}x${size}+4+4',
				 image    => $image1);

	# load template and put them together
#    `convert $template_file -geometry +4+4 $image  -composite $dst`;

	$image->Comment("Converted from $src_file");
	mkpath4icon($dst_file);
	$rc = $image->Write($dst_file);
	warn "!!!!!! ERROR: $rc" if "$rc";
	};
    warn "!!!!!! ERROR: $@" if $@;
	     }


##################################################################
# Get the licence from a svg File
# RETURNS: 
#     'PD' for PublicDomain
#     '?'  if unknown
sub get_svg_license($){
    my $icon_file=shift;
    my $license="?";
    eval {
	my $icon = XMLin($icon_file,ForceArray => ['description','title','condition']);
	$license = $icon->{'metadata'}->{'rdf:RDF'}->{'cc:Work'}->{'cc:license'}->{'rdf:resource'};
	#print Dumper(\$license);
	return '?' unless $license; 
	#    $license =~ s,http://web.resource.org/cc/,,;
	#    return "Public Domain" if $license && $license =~ m/Public.*Domain/;
    };
    warn "!!!!!! ERROR: $@" if $@;

    return $license;
		}


##################################################################
# create all Thumbnails for one icon-name
# currently this means
#       svg         --> svg-png
#   and svg-twotone --> svg-twotone-png
#   and japan       --> japan-png
sub create_png()
{ 
    my $icon_file = $File::Find::name;
    my $icon_dir = $File::Find::dir;
    return if $icon_file =~ m/\.svn/;

    print STDERR "create_png( $icon_file )\n" if $DEBUG>0;

    if ( $icon_file =~ m/\.svg$/ ) {
	$COUNT_FILES_SEEN++;
	my $dst_file=$icon_file;
	for my $theme ( @theme_dirs) {
	    $dst_file =~ s,/$theme/,/${theme}-png/,;
	}
	$dst_file =~ s,\.svg$,.png,;
	update_svg_thumbnail($icon_file,$dst_file);
    }
}

# ------------------------------------------------------------------
# ARGS:
#   gets an string with the svg image
# RETURNS: ($x,$y) the x/y entents of this svg FIle
sub get_svg_size_of_image($){
    my $image_string=shift;
    my ($x,$y)=(200,200);
    if ( $image_string=~ m/viewBox=\"([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s*\"/ ){
	my ( $x0,$y0,$x1,$y1 ) = ($1,$2,$3,$4);
	#print STDERR "		( $x0,$y0,$x1,$y1)" if $VERBOSE;
	$x0=0 if $x0>0;
	$y0=0 if $y0>0;
	$x=int(2+$x1-$x0);
	$y=int(2+$y1-$y0);
    } elsif ( $image_string=~ m/height=\"([\-\d\.]+)\"/ ){
	$y=int(2+$1);
	if ( $image_string=~ m/width=\"([\-\d\.]+)\"/ ){
	    $x=int(2+$1);
	}
    } else {
	warn "No Size information found using $x/$y\n";
    }
    # Limit used memory of Image::Magic
    $x=4000 if $x>4000;
    $y=4000 if $y>4000;
    return ($x,$y);
}

#############################################################################
#
# Create/Update Thumbnail for svg
sub update_svg_thumbnail($$){
    my $icon_svg = shift;
    my $icon_png = shift;

    print STDERR "update_svg_thumbnail: check($icon_svg,	$icon_png)\n" if $DEBUG>0;

    if ( ! -s $icon_svg ) {
	die "Icon '$icon_svg' not found\n";
    }

    my $mtime_svg = (stat($icon_svg)->mtime)|| 0; 
    my $mtime_png = 0;
    $mtime_png = (stat($icon_png)->mtime) if -s $icon_png;
    if ( $mtime_png >  $mtime_svg) {
	# Up to Date
	return;
    } else {
	$DEBUG && print STDERR "time_diff($icon_svg)= ".($mtime_png -  $mtime_svg)."\n";
    }

    my $license = get_svg_license($icon_svg);
    my $image_string = File::Slurp::slurp($icon_svg);
    my ($x,$y)=get_svg_size_of_image( $image_string);

    if ($VERBOSE || $DEBUG ) {
	print STDERR "Updating $icon_svg\t-->  $icon_png\t";
	print STDERR " => '${x}x$y' lic:$license" if $VERBOSE;
	print STDERR "\n";
    }
    eval { # in case image::magic dies
	my $image = Image::Magick->new( size => "${x}x$y");;
	my $rc = $image->Read($icon_svg);
	if ( "$rc") {
	    warn "!!!!!! ERROR: reading '$icon_svg': $rc\n";
	    return;
	}
	if ( $icon_svg !~ /incomming/ ) {
	    $rc = $image->Sample(geometry => "32x32+0+0");
	    if ( "$rc") {
		warn "!!!!!! ERROR: resize 32x32 '$icon_svg': $rc\n";
		return;
	    }
	}

	# For debugging the svg pictures; you can use this line
	#$rc = $image->Sample(geometry => "128x128+0+0") if $x>128 || $y>128;
	warn "!!!!!! ERROR: $rc" if "$rc";
	
	$rc = $image->Transparent(color=>"white");
	warn "!!!!!! ERROR: Transparent: $rc" if "$rc";

	my $dir=dirname($icon_png);
	if ( ! -d $dir ) {
	    mkpath($dir) || warn ("Cannot create Directory: '$dir'");
	} 

	$image->Comment("License: $license") if $license;

	$rc = $image->Write($icon_png);
	warn "!!!!!! ERROR: writing '$icon_png': $rc" if "$rc";

	};
    warn "!!!!!! ERROR: $@" if $@;
    $COUNT_FILES_CONVERTED++;

}



# ---------------------- MAIN ----------------------

# -------------------------------------------- Copy Files from src-dir if newer
if ( $do_copy_from_source ) {
    if ( ! -d $dst_dir ) {
	mkpath($dst_dir) || warn ("Cannot create Directory: '$dst_dir'");
    };
    print STDERR "Copy Icons from $src_dir	-->	$dst_dir\n" if $DEBUG>0;

    for my $dir ( qw(square.big square.small
              classic.big classic.small
              svg
              svg-twotone
              japan
              nickw
              )) {
	# Copy Files
	for my $src_file ( split(/\s+/,`find $src_dir/$dir -name "*.svg" -o -name "*.png"` )) {
	    next if $src_file =~ m,/.svn/,;
	    my $dst_file = $src_file;
	    $dst_file =~ s,$src_dir,$dst_dir,;
	    my $time_src = (stat($src_file)->mtime);
	    my $time_dst = 0;
	    $time_dst = (stat($dst_file)->mtime) if -s $dst_file;
	    next if $time_src < $time_dst;
	    mkpath4icon($dst_file);
	    print "copy $src_file $dst_file\n" if $VERBOSE || $DEBUG;
	    my $rc = copy($src_file,$dst_file);
	    if ( $rc != 1 ) {
		warn "!!!!!! ERROR: Copying ($src_file,$dst_file): $rc: $!\n";
	    };
	}
    }
}


# -------------------------------------------- Update Thumbnails

if ( $do_update_thumbnails) {

    die "Can't find dir \"$dst_dir\""
	unless -d $dst_dir;


    print "Update Thumbnails for Icons in Directory '$dst_dir'\n";
    find( { no_chdir=> 1,
	    wanted => \&create_png,
	  },
	  "$dst_dir/svg",
	  "$dst_dir/svg-twotone",
	  "$dst_dir/japan"
	);

    print "Thumbnails seen:  $COUNT_FILES_SEEN\n";
    print "Thumbnails converted: $COUNT_FILES_CONVERTED\n";
}
if ( $do_merge_icons ) {

    # -------------------------------------------- Merge Icons between themes
    my $conv_string="Converted from http://svn.openstreetmap.org/applications/share/map-icons";
    my ($src_theme,$dst_theme);

    if ($VERBOSE || $DEBUG ) {
	print "Merging in directory '$dst_dir'";
	print "\n";
    }

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
	mkpath4icon($dst);
	my $rc = copy($src,$dst);
	if ( $rc != 1 ) {
	    warn "!!!!!! ERROR: Copying ($src,$dst): $rc: $!\n";
	    warn `pwd`."\n";
	    warn `ls -l $src`."\n";
	};
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
    print "	convert $src	-scale 32x32 $dst\n"    
	if $VERBOSE || $DEBUG ;
    image_resize($src,$dst,32);
# -comment "${conv_string}/classic.small"
}

($src_theme,$dst_theme)=qw(classic.big square.big);
print "$src_theme	-->	$dst_theme\n";
for my $src (
    split(/\s+/,
	  `find "$dst_dir/$src_theme/" -name "*.png" | grep -v -e incomming -e empty.png` ) ) {
    # merge and convert an image from classic.big to square.big
    my $dst=$src;
    $dst =~ s,$src_theme,$dst_theme,;

    next unless -s $src;
    next if -s $dst;

    $DEBUG && print "Try to create $src	========> $dst\n";

    my $empty=dirname($dst)."/empty.png";
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
    print "	merging: $empty + $src --> $dst\n"
	if $VERBOSE || $DEBUG;
    mkpath4icon($dst);
    image_merge($empty,$src,$dst);
#    `convert $empty -geometry +4+4 /tmp/reduced.png  -composite $dst`;
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
    print "	convert $src	-scale 16x16 $dst\n"
	if $VERBOSE || $DEBUG ;
    image_resize($src,$dst,16);
    #  -comment "$conv_string/square.big"
}

print "Merging icons across Themes complete\n";

}

__END__

=head1 NAME

B<compile_icons.pl> Version 0.1

=head1 DESCRIPTION

B<compile_icons.pl>  Convert/merges icons
This is used to get as many Icons as possible.
So if you have a convertable Icon you have the chance to get icons 
for all other themes too.
Before merging the Icons between the different themes, we create/update 
the thumbnails corresponding to the svg icons.
Thumbnails are created for all svg Files in the 
themes directories japan/svg/svg-twotone 
All icon-thumbnails will be placed into there dst-dir directory.

=head1 SYNOPSIS

B<Common usages:>

compile_icons.pl [-d] [-h] [--man] <build-directory>

=over

=item B<--dst-dir>

The Destination Directory. Default is ./build/

=item B<--src-dir>

The Source Directory. Default is ./

=item B<--update-thumbnails>

Only update thumbnails

=item B<--merge-icons>

Only merge Icons

=item B<--man>

Print this small usage

=item B<-h>

Print small Help

=item B<-d>

Add some more Debug Output

=back
