#!/usr/bin/perl -w
# This little helper copies according to the icons.xml File
# and the geoinfo->restrictions tag
# all icons will be placed into there package directory

use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use File::Basename;
use File::Path;
use File::Copy;

my $file = 'icons';

die "Can't find file \"$file.xml\""
    unless -f "$file.xml";

my $dst_path="/usr/share/map-icons";
my $src_dir="build/";
my $package_path = {
    ''      => 'debian/openstreetmap-map-icons',
    'brand' => 'debian/openstreetmap-map-icons-restricted',
};


my @theme_dirs=qw(classic.big classic.small 
		  jp jp_tn
		  nickw
		  square.big square.small
		  svg svg_tn
		  );

#-----------------------------------------------------------------------------
my $rules = XMLin("$file.xml");
my @rules=@{$rules->{rule}};
for my $rule (@rules) {
    #print Dumper(\$rule);
    my $restricted = $rule->{'geoinfo'}->{'restricted'}||'';
    my $name = $rule->{'geoinfo'}->{'name'};
    $name =~s,\.,/,;
    if ( ! defined($package_path->{$restricted})) {
	die "Wrong or unknown restriction '$restricted'\n";
    }
    
    for my $theme ( @theme_dirs) {
	for my $fn_icon ( "$theme/$name.png","$theme/$name.svg"){
	    my $src_fn="$src_dir/$fn_icon";
	    my $dst_fn=$package_path->{$restricted}."$dst_path/".$fn_icon;
	    if ( -s $src_fn) {
		# print "$fn_icon	---> $dst_fn\n";
		mkpath dirname($dst_fn);
		copy($src_fn,$dst_fn);
	    }
	}
    };
};
 
my $write_output=0;
if ( $write_output) {
    my $xml = XMLout($rules);
    my $fo = IO::File->new(">$file-out.xml");
    print  $fo $xml;
    $fo->close();
}

