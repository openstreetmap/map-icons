#!/usr/bin/perl -w
# This little helper copies according to the icons.xml File
# all icons will be placed into there package directory
# For more Info see --man option

use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use File::Basename;
use File::Path;
use File::Copy;
use Getopt::Long;
use Pod::Usage;

my $file = 'icons';

die "Can't find file \"$file.xml\""
    unless -f "$file.xml";

my $dst_path="usr/share/icons/map-icons";
my $src_dir="build/";
my $package_path = 'debian/openstreetmap-map-icons';


my @theme_dirs=qw(classic.big classic.small 
		  japan japan_tn
		  nickw
		  square.big square.small
		  svg svg_tn
		  );

my ($man,$help,$DEBUG,$VERBOSE)=(0,0,0,0);
my $NO_RESTRICTED=0;
# Set defaults and get options from command line
Getopt::Long::Configure('no_ignore_case');
GetOptions ( 
	     'd+'                 => \$DEBUG,
	     'debug+'             => \$DEBUG,      
	     'verbose'            => \$VERBOSE,
             'exclude-restricted' => \$NO_RESTRICTED,
	     'v+'                 => \$VERBOSE,
	     'h|help|x'           => \$help, 
	     'MAN'                => \$man, 
	     'man'                => \$man, 
	     )
    or pod2usage(1);

pod2usage(1) if $help;
pod2usage(-verbose=>2) if $man;


#-----------------------------------------------------------------------------
my $rules = XMLin("$file.xml",
		  ForceArray => [ 'condition' ],
    );
my @rules=@{$rules->{rule}};
for my $rule (@rules) {
    print Dumper(\$rule) if $DEBUG >10;
    my $restricted = $rule->{'geoinfo'}->{'restricted'}||'';
    my $names = $rule->{'condition'};
    my ($name) = grep { $_->{k} =~ /^poi|rendering$/ } @{$names};
    $name = $name->{v};
    print "name: '$name'\n" if $VERBOSE;
    if ( ! $name ) {
	warn "Undefined Name\n";
	warn Dumper(\$rule);
	next;
    }
    $name =~ s,\.,/,g;

    # Do not copy the restricted Icons
    # This is untested, but might work ;-)
    if ( $NO_RESTRICTED && $restricted ) {
	next;
    }

    for my $theme ( @theme_dirs) {
	#print STDERR "Copy  $theme/$name for Theme\n";
	my $found=0;
	for my $fn_icon ( "$theme/$name.png","$theme/$name.svg"){
	    my $src_fn="$src_dir/$fn_icon";
	    my $dst_fn="${package_path}-${theme}/$dst_path/$fn_icon";
	    if ( -s $src_fn) {
		print STDERR "$fn_icon	---> $dst_fn\n" if $VERBOSE>2 || $DEBUG;
		my $dir = dirname($dst_fn);
		mkpath $dir  || warn "Cannot create $dir:$!\n";
		copy($src_fn,$dst_fn)  || warn "Cannot copy $src_fn,$dst_fn:$!\n";;
		$found++;
	    }    
	}
	# print STDERR "No File for $theme/$name found\n" unless $found;
    };
};
 
my $write_output=0;
if ( $write_output) {
    my $xml = XMLout($rules);
    my $fo = IO::File->new(">$file-out.xml");
    print  $fo $xml;
    $fo->close();
}


__END__

=head1 NAME

B<copy_icons_to_debian_package_dirs.pl> Version 0.1

=head1 DESCRIPTION

B<copy_icons_to_debian_package_dirs.pl> is a program to copy 
the icons Files into the apropriate debian Directories.
This little helper copies according to the icons.xml File 
all files into the new structure.
All icons will be placed into there package directory
the default src_dir if build/*


=head1 SYNOPSIS

B<Common usages:>

geoinfo.pl [-d] [--man]

=item B<--man>

Print this small usage

=item B<-d>

Add some more Debug Output

=back
