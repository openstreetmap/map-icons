#!/usr/bin/perl
#####################################################################
#
#  This script creates an overview.html from the XML-File to
#  show all available poi_types and icons.
#  It has to be run from the data directory.
#

#use diagnostics;
use strict;
use warnings;

use utf8;
use IO::File;
use File::Find;
use Getopt::Std;
use Pod::Usage;
use File::Basename;
use File::Copy;
use File::Path;
use Data::Dumper;
use XML::Simple;
use Image::Info;
use Cwd;

our ($opt_b, $opt_h, $opt_i, $opt_j, $opt_p, $opt_r,$opt_v, $opt_D, $opt_F, $opt_L, $opt_P,$opt_S) = 0;
getopts('bhijprvF:D:L:P:S:') or $opt_h = 1;
pod2usage( -exitval => '1',  
           -verbose => '1') if $opt_h;

$opt_b ||=0;
my $cwd = cwd;
my $languages = $opt_L || "en,de";
my $icon_types = "all,poi,dynamic,general,rendering";
my $base_dir = $opt_D || cwd;
my $file_xml = $opt_F || './icons.xml';
my $i = 0;
my $poi_reserved = 30;
my $poi_type_id_base = $poi_reserved;
my $VERBOSE = $opt_v;
$opt_P ||= "index";

my @ALL_TYPES = qw(square.big square.small classic.big classic.small svg svg-twotone japan nickw);

sub html_head($$);
sub update_overview($$$);

#####################################################################
#
#  M A I N
#
#
my $rules = XMLin("$file_xml",ForceArray => ['description','title','condition','condition_2nd','condition_3rd']);
my @rules=@{$rules->{rule}};

for my $type ( split ( ",", $icon_types)){
    for my $lang ( split ( ",", $languages)){
        update_overview($type, $lang,\@rules);	 # update html overview from XML-File
    }
}

exit (0);


sub html_head($$){
    my $type = shift;
    my $lang = shift;
    my $title = 'All available icons';
    if ($type ne 'all'){
        $title = 'Available icons of type "'.$type.'"'
    }
    # html 'template'
    my $html_head =
	"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n".
	"  \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n".
	"<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" ".
	"xml:lang=\"en\">\n".
	"<head>\n".
	"<meta http-equiv=\"Content-Type\" ".
	"content=\"text/html; charset=utf-8\" />\n".
	"\n".
	"<title>".$title."</title>\n".
	"<style type=\"text/css\">\n".
	"       table            { width:100%;  background-color:#fff8B2; }\n".
	"	tr               { border-top:5px solid black; }\n".
	"	td               { border-bottom:1px solid #888888; }\n".
	"	tr.id            { background-color:#6666ff; color:white; font-weight:bold; }\n".
	"	td.id            { text-align:right; vertical-align:top;}\n".
	"	td.icon          { text-align:center; vertical-align:top;}\n".
	"	td.status        { text-align:left; vertical-align:top;}\n".
	"	td.empty         { text-align:center; height:32px; }\n".
	"	img              { border:0px; }\n".
	"	img.square_big   { border:0px; width:32px; height:32px; }\n".
	"	img.square_small { border:0px; width:16px; height:16px; }\n".
	"	img.classic      { border:0px; max-height:32px; }\n".
	"	img.svg          { max-height:32px; }\n".
	"	img.japan        { max-height:32px; }\n".
	"	img.svg-twotone  { max-height:32px; }\n".
	"	img.nickw        { max-height:32px; }\n".
	"	span.desc        { font:x-small italic condensed }\n".
	"	h1               { text-align:center; }\n".
	"</style>\n".
	"</head>\n";
    $html_head .= "<body style=\"background-color:#bbbbbb;\">\n";


    if ( $lang eq "de" ) {
        $html_head .= '<h1>Verf&uuml;gbare Icons des Typs "'.$type."\"</h1>\n";
    } else {
        $html_head .= '<h1>Available icons of type "'.$type."\"</h1>\n";
    };

    # Legende
    $html_head .= "<table>\n";
    $html_head .= "<tr>\n";
    if ( 1 ) { # Content with links
	$html_head .= "<td valign=\"top\">\n";
	if ( $lang eq "de" ) {
	    $html_head .= "<h3>Kategorien</h3>\n";
	} else {
	    $html_head .= "<h3>Categories</h3>\n";
	};

	$html_head .= "<table><tr><td valign=\"top\">\n";
	$html_head .= "<font size=\"-2\"><ul>\n";
	#for my $rule (@{$rules}) {
	my %top_categories;
	for my $dir ( sort glob ( "$base_dir/*/*")) {
	    next unless -d $dir;
	    next if  $dir =~ m/CMakeFiles/;
	    my ($cat) = ($dir =~ m/.*\/(.+)(\.svg|\.png)?$/ );
#	    print "$cat\t$dir\n";
	    $top_categories{$cat}++;
	}
	my @top_categories;
	@top_categories = (sort keys %top_categories);
	my $cat_count=1;
	for my $top_level ( @top_categories ) {
	    $html_head .= "	<li><a href=\"\#$top_level\">$top_level</a></li>\n";
	    $html_head .= "\n	</font></ul></td><td valign=\"top\"><ul><font size=\"-2\">\n" 
		unless $cat_count++ % 5;
	}
	$html_head .= "</font></ul>\n";
	$html_head .= "</td></tr></table>\n";
	$html_head .= "</td>\n";
    }

    $html_head .= "\n";
    $html_head .= "<td valign=\"top\">\n";

    # Links to other Versions
    if (0) {
	$html_head .= "\n";
	$html_head .= "<table border=\"1\">\n";
	$html_head .= "<td valign=\"top\">\n";
	$html_head .= "<a href=\"overview.en.html\">Without License Info in English</a><br/>\n";
	$html_head .= "<a href=\"overview.de.html\">Without License Info in German</a><br/>\n";
	$html_head .= "</td>\n";
	$html_head .= "</table>\n";
    };
    
    $html_head .= "\n";
	$html_head .= "</table>\n";


    $html_head .= "</td>\n";
    $html_head .= "</tr>\n";
    $html_head .= "</table>\n";
    $html_head .= "\n";
    $html_head .= "\n";


    $html_head .= "<table border=\"$opt_b\">\n";
    $html_head .= "  <tr>";
    $html_head .= "    <th>ID</th>" if $opt_j;
    $html_head .= "    <th>Name</th>\n";
    $html_head .= "    <th>Path</th>\n" if $opt_p;
    my $cols_per_icon= 1;
    $html_head .= "    <th colspan=\"".($cols_per_icon*scalar(@ALL_TYPES))."\">Icons</th>\n";
    $html_head .= "    <th>Description</th>\n";
    $html_head .= "    <th>OSM Condition</th>\n";
    $html_head .= "  </tr>\n";
    return $html_head;
}

# Header with a list of all types used in one <tr> line
sub all_type_header(){
    my $all_type_header= "<tr>";
    $all_type_header .= "<td></td>" if $opt_j;
    $all_type_header .= " <td></td>";
    $all_type_header .= " <td></td>\n" if $opt_p;
    for my $type ( @ALL_TYPES  ) {
	my $txt=$type;
	$txt=~s/\.$//;
	$txt=~s/\./<br>/;
	$all_type_header .= " <td  valign=\"top\"><font size=\"-3\">$txt</font></td>\n";
    }
    $all_type_header .= " <td></td>\n";
    $all_type_header .= " <td></td>\n";
    $all_type_header .= " <td></td>\n";
    $all_type_header .= " </tr>\n\n";
    return $all_type_header;
}

#####################################################################
#
#  Update HTML Overview of available Icons and POI-Types
#
#
sub update_overview($$$){
    my $type = shift;
    my $lang  = shift || 'en';
    my $rules = shift;
    my $file_html = "$base_dir/${opt_P}_${type}.${lang}.html";

    print STDOUT "----- Updating HTML Overview '$file_html' -----\n";
    
    my %out;

    my $ID_SEEN={};
    for my $rule (@{$rules}) {
	my $content = '';
	my $name = $rule->{v};
	my $id = $name;
        if ( $type ne "all" ) {
	    next if ( $rule->{k} ne $type && $name =~ m/\./)
        }
	print "name: '$name'\n" if $VERBOSE;
	if ( ! $name ) {
	    warn "Undefined Name\n";
	    warn Dumper(\$rule);
	    next;
	}
	my $restricted = $rule->{'restricted'};

	if ( $id && defined($ID_SEEN->{$id}) && "$ID_SEEN->{$id}" ){
	    die "$id was already seen at $ID_SEEN->{$id}. Here in $name\n";
	};
	$ID_SEEN->{$id}=$name;

	if ( $restricted && not $opt_r ){
	    next;
	}

	my $title='';
	for my $t ( @{$rule->{'title'}||[]} ){
	    $title = $t->{content}
	    if $t->{'lang'} eq $lang && $t->{content};
	}
	
	my $descr ='';
	for my $d (@{$rule->{'description'}}) {
	    my $c = $d->{content};
	    if ($d->{'lang'} eq $lang && $c) {
		$descr = '<span class="desc">&nbsp;&nbsp;'.$c.'</span>';
	    }
	}
	
        my $conditions='';
	for my $c (@{$rule->{'condition'}}) {
	    next if $c->{k} eq "poi";
	    $conditions .= "$c->{k}=$c->{v}<br>";
	}

	for my $c2 (@{$rule->{'condition_2nd'}}) {
	    next if $c2->{k} eq "poi";
	    $conditions .= " + $c2->{k}=$c2->{v}<br>";
	}

	for my $c3 (@{$rule->{'condition_3rd'}}) {
	    next if $c3->{k} eq "poi";
	    $conditions .= " ++ $c3->{k}=$c3->{v}<br>";
	}


	my $icon = $name;
	my $ind = $name;

	# accentuate base categories
	my $header_line=0;
	if ($id !~ m/\./ || ( $icon !~ m,\.,) )	{
	    $content .= "  <tr><td>&nbsp;</td></tr>\n";
	    $content .=     all_type_header();
	    $content .= "  <tr class=\"id\">\n";
	    $content .= "     <td class=\"id\">$id</td>\n" if $opt_j;
	    $content .= "     <td>&nbsp;<a name=\"$name\">$name</a></td>\n";
	    $header_line++;
	} else {
	    my $level = ($icon =~ tr,\.,/,);
	    my $html_space = '';
	    while ($level)
	    { $html_space .='&nbsp;&nbsp;&nbsp;&nbsp;&rsaquo;&nbsp;'; $level--; };
	    $name =~ s,.*\.,,g;
	    $content .= "<tr>\n";
	    $content .= "    <td class=\"id\">$id</td>" if $opt_j;
	    $content .= "    <td>&nbsp;$html_space$name</td>\n";
	}

	# Add filename+path column
	$content .= "<td><font size=-4>$icon</font></td>\n" 
	    if $opt_p;

	# display all icons
	for my $type ( @ALL_TYPES  ) {
	    my $icon_s = "${type}/$icon.svg";
	    my $icon_p = "${type}/$icon.png";
	    my $icon_t = "${type}-png/${icon}.png";
	    my $class = $type;
	    $class =~ s/\./_/g;

	    my $icon_path_current;
	    if ( -s "$base_dir/$icon_t" ) { $icon_path_current = $icon_t; }
	    else {		$icon_path_current = $icon_p;   };

	    my $svn_bgcolor='';
	    
	    $content .=  "    <td ";
	    my $empty= ! ( -s "$base_dir/$icon_p" or -s "$base_dir/$icon_s");
	    if ( $empty ) { # exchange empty or missing icon files with a char for faster display
		$content .=  " class=\"empty\" " unless $header_line;
	    } elsif ( $restricted && not $opt_r ){
		$content .=  " class=\"empty\" " unless $header_line;
	    } else {
		$content .=  " class=\"icon\" " unless $header_line;
	    }

	    # -------------- Add license Information Part 1
	    my $license='';
	    my $lic_color=' ';
	    my $lic_bgcolor=' ';

	    $content .=  " >";


	    if ( $empty ) { # exchange empty or missing icon files with a char for faster display
		$content .=  ".";
	    } elsif ( $restricted && not $opt_r ){
		$content .=   "r";
	    } else {
		if ( -s "$base_dir/$icon_path_current" ){
		    $content .= "     <a href=\"$icon_path_current\" >\n";
		    $content .= "                 <img title=\"$name\" src=\"$icon_path_current\" class=\"$class\" alt=\"$name\" />";
		    $content .= "</a>";
		}
	    }
	    $content .= "</td>\n";

	}
	$content .= "    <td>$title<br>$descr</td>\n";
	$content .= "    <td><font size=-1>$conditions</font></td>\n";
	$content .= "  </tr>\n";
	$out{$ind} = $content;
    }  

    # create backup of old overview.html

    my $fo = IO::File->new(">$file_html");
    $fo ||die "Cannot write to '$file_html': $!\n";
    $fo->binmode(":utf8");
    print $fo html_head($type,$lang);
    # sorted output
    foreach ( sort keys(%out) )  {
	print $fo $out{$_};
    }

    print $fo "</table>\n";
    if ( $opt_i ) {
	print $fo "<h3>Incomming Directories</h3>\n";
	
	for my $theme ( @ALL_TYPES ) {
	    my $ext = "png";
	    $ext = "svg" if $theme =~ m/svg|japan/;
	    print $fo "<br>\n";
	    print $fo "Incomming for $theme\n";
	    print $fo "<table border=\"1\">\n";
	    print $fo "<tr>\n";
	    my $count=0;
	    print STDERR "glob($theme/incomming/*.$ext)\n";
	    for my $icon ( glob("$theme/incomming/*.$ext" ) ){
		print STDERR "$icon\n" if $VERBOSE;
		my $name = $icon;
		$name =~ s/.*\/incomming\///;
		$name =~ s/\.(svg|png)$//;
		my $icon_t = $icon;
		$icon_t =~ s/\//-png\//;
		$icon_t =~ s/\.svg/\.png/;
		print STDERR "thumb: $icon_t\n" if $VERBOSE;
		$icon_t = $icon unless -s $icon_t;
		my $content = "     <a href=\"$icon_t\" >";
		$content .= "         <img alt=\"$icon\" title=\"$icon\" src=\"$icon_t\" />";
		$content .= "<br/>$name\n";
		$content .= "</a>\n";
		print $fo "    <td>$content</td>";

		if ( $count++ > 5) {
		    $count=0;
		    print $fo "</tr><tr>\n";
		}
	    }
	    print $fo "</tr>\n";
	    print $fo "</table>\n";

	}
    }


    print $fo "\n</body>\n</html>";
    $fo->close();
    return;

}


__END__


=head1 SYNOPSIS
 
create_overview.pl [-h] [-v] [-i] [-r] [-s] [-F XML-FILE] [-D DIR] [-P FILENAME_PREFIX]
 
=head1 OPTIONS
 
=over 2
 
=item B<--h>

Show this help

=item B<-F> XML-FILE

Set file, that holds all the necessary icon and poi_type information.
The default file is 'icons.xml'.

=item B<-D> DIRECTORY

The directory to search for the icons. Default it CWD (./)

=item B<-v>

Enable verbose output

=item B<-i>

Add incomming directory to the end of the 
overview.*.html file.

=item B<-j>

show internal gpsdrive-mysql id in html page

=item B<-r>

Include restricted icons in overview.html

=item B<-p>

Show path of Filename

=item B<-b>

Add Border to Table

=item B<-L language>

Update only this language. Default is en,de

=item B<-P FILENAME-PREFIX>

Use this for the filename Prefix. Default: overview

=item B<-S SVN-BASE>

Use the Directory  SVN-BASE as Base for determining SVN Status

=back
