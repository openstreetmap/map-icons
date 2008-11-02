#!/usr/bin/perl -w
# This little helper traverses the build tree and tries to add 
# missing symbols/icons which can be created
# by resizing/converting/combining other existing images

use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use File::Basename;
use File::Path;
use File::Copy;
use File::Find;
use File::Slurp;
use Image::Magick;
use Getopt::Long;
use Pod::Usage;

# Set defaults and get options from command line
my ($man,$help,$DEBUG,$VERBOSE)=(0,0,0,0);
Getopt::Long::Configure('no_ignore_case');
GetOptions ( 
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



my $base_dir=$ARGV[0];

die "Can't find dir \"$base_dir\""
    unless -d $base_dir;

my @theme_dirs=qw(classic.big classic.small 
		  japan
		  nickw
		  square.big square.small
		  svg
                  svg-twotone
		  );

sub update_svg_thumbnail($$);
sub create_png();

our $COUNT_FILES_SEEN=0;
our $COUNT_FILES_CONVERTED=0;
# ---------------------- MAIN ----------------------


print "Update Thumbnails for Icons in Directory '$base_dir'\n";
find( { no_chdir=> 1,
	wanted => \&create_png,
      },
    "$base_dir/svg",
    "$base_dir/japan",
    "$base_dir/svg-twotone"
    );

print "Thumbnails seen:  $COUNT_FILES_SEEN\n";
print "Thumbnails converted: $COUNT_FILES_CONVERTED\n";

exit;

# ------------------------------------------------------------------

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
    warn "ERROR: $@" if $@;

    return $license;
}


##################################################################
# create all Thumbnails for one icon-name
# currently this means svg --> svg-png and japan --> japan-png
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
sub get_svg_size_of_imge($){
    my $image_string=shift;
    my ($x,$y)=(200,200);
    if ( $image_string=~ m/viewBox=\"([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)\s*\"/){
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
    my $icon_svt = shift;

    print STDERR "update_svg_thumbnail($icon_svg,	$icon_svt)\n" if $DEBUG>0;

    if ( ! -s $icon_svg ) {
	die "Icon '$icon_svg' not found\n";
    }

    my $mtime_svt = (stat($icon_svt))[9]||0;
    my $mtime_svg  = (stat($icon_svg))[9]||0; 
     if ( $mtime_svt >  $mtime_svg) { # Up to Date
	 return;
     } else {
#	print "time_diff($icon_svg)= ".($mtime_svt -  $mtime_svg)."\n";
     }

    my $license = get_svg_license($icon_svg);
    my $image_string = File::Slurp::slurp($icon_svg);
    my ($x,$y)=get_svg_size_of_imge( $image_string);

    print STDERR "Updating $icon_svg\t-->  $icon_svt\t";
    print STDERR " => '${x}x$y' lic:$license" if $VERBOSE;
    print STDERR "\n";
    eval { # in case image::magic dies
	my $image = Image::Magick->new( size => "${x}x$y");;
	my $rc = $image->Read($icon_svg);
	warn "$rc" if "$rc";
	if ( $icon_svg !~ /incomming/ ) {
	    $rc = $image->Sample(geometry => "32x32+0+0");
	}

	# For debugging the svg pictures; you can use this line
	#$rc = $image->Sample(geometry => "128x128+0+0") if $x>128 || $y>128;
	warn "ERROR: $rc" if "$rc";
	
	$rc = $image->Transparent(color=>"white");
	warn "ERROR: $rc" if "$rc";

	my $dir=dirname($icon_svt);
	if ( ! -d $dir ) {
	    mkpath($dir) || warn ("Cannot create Directory: '$dir'");
	} 

	$image->Comment("License: $license") if $license;

	$rc = $image->Write($icon_svt);
	warn "ERROR: $rc" if "$rc";

    };
    warn "ERROR: $@" if $@;
    $COUNT_FILES_CONVERTED++;

}



__END__

=head1 NAME

B<update_thumbnails.pl> Version 0.1

=head1 DESCRIPTION

B<update_thumbnails.pl> is a program to update the thumbnails 
corresponding to the svg icons.
This little helper creates thumbnails for all svg Files in the japa/svg/svg-
All icon-thumbnails will be placed into there package directory
the default src_dir if build/*


=head1 SYNOPSIS

B<Common usages:>

update_thumbnails.pl [-d] [-h] [--man] <build-directory>

=over

=item B<--man>

Print this small usage

=item B<-h>

Print small Help

=item B<-d>

Add some more Debug Output

=item B<build-directory>

The directory where we search for the icons. This is also the
directory where the thunbnails are written


=back
