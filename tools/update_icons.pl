#!/usr/bin/perl
#
# This script is currently deprecated.
# But we will keep it for now, since one might be able to use 
# part of the code to write a checker to show newly added icons.
#

exit -1



#####################################################################
#
#  This script handles the XML-Files for the POI-Types in gpsdrive.
#  It has to be run from the data directory.
#  
#  Default actions, when no options are given:
#  - Create basic XML-File if none is available
#  - Search icons directories for PNG files
#  - Add those files as new POI-Types if they are not yet existent
#  - Create overview.html from the XML-File to show all
#    available poi_types and icons.
#
#####################################################################
#
#  Scheme for the entries (only poi_type relevant elements are shown):
#
#  <rule>
#    <condition k="poi" v="$NAME" />
#    <scale_min>$SCALE_MIN</scale_min>
#    <scale_max>$SCALE_MAX</scale_max>
#    <title lang="$LANG">$TITLE</title>
#    <description lang="$LANG">$DESCRIPTION</description>
#  </rule>
#
#####################################################################

#use diagnostics;
use strict;
use warnings;

use utf8;
use IO::File;
use File::Find;
use File::Copy;
use XML::Twig;
use Getopt::Std;
use Pod::Usage;
use Image::Magick;
use File::Slurp;
use File::Basename;
use File::Path;
use Data::Dumper;

our ($opt_v, $opt_f, $opt_h, $opt_i, $opt_n, $opt_r,$opt_s) = 0;
getopts('hvinrsf:') or $opt_h = 1;
pod2usage( -exitval => '1',  
           -verbose => '1') if $opt_h;

my $file_xml = './icons.xml';
my %ICONS = ('','');
my $i = 0;
my $j = 0;
my $default_scale_min = 1;
my $default_scale_max = 100000;
my $default_title_en = '';
my $default_desc_en = '';
my $VERBOSE = $opt_v;

my @ALL_TYPES = qw(square.big square.small classic.big classic.small svg svg-twotone japan );


#####################################################################
#
#  M A I N
#
#
chdir('./map-icons');
unless (-e $file_xml)
{
  create_xml();	# Create a new XML-File if none exists
}
get_icons();		 # read available icons from dirs
update_xml();	         # parse and update contents  of XML-File
chdir('..');
exit (0);



#####################################################################
#
#  Parse available XML-File aund update with contents from icons dirs
#
#
sub update_xml
{
  print STDOUT "\n----- Parsing and updating '$file_xml' -----\n";
  
  # Parse XML-File and look for already existing POI-Type entries
  #
  my $twig= new XML::Twig
    (
      pretty_print => 'indented',
      empty_tags => 'normal',
      comments => 'keep',
      TwigHandlers => { 
	  condition => \&sub_condition # also deletes the entry from %ICONS
     }
    );
  $twig->parsefile( "$file_xml");	# build the twig
  my $rules= $twig->root;	# get the root of the twig (rules)

  # Insert new POI-Type entries from hash of available icons
  #
  $i = 0;
  my @tmp_icons = sort(keys(%ICONS));
  
  for my $icon (@tmp_icons)
  {
     insert_poi_type($icon,\$rules);
     $i++;
  }
  print STDOUT "  New POI-Types added:\t$i\n";

  # Print Status for poi_type_ids
  #
  my @rule= $rules->children;	# get the updated rule list

  $i = $j = 0;
  foreach my $entry (@rule)
  {
      my $condition=$entry->last_child('condition');
      if  ( $condition && $condition->{'att'}->{'k'} eq 'poi' )
	  {
	      $i++;
	  }
      if  ( $condition && $condition->{'att'}->{'k'} eq 'rendering')
	  {
	      $j++;
	  }
  }
  print STDOUT "  Defined Points of Interest  :\t$i\n";
  print STDOUT "  Defined Map Rendering Icons :\t$j\n";

  # Write XML-File containing modified contents
  #
  open TMPFILE,">:utf8","./icons.tmp";
    select TMPFILE;
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print "<rules>\n";
    
    my $j=1;


sub entry_name($){
    my $entry = shift;
    my $condition = $entry->last_child('condition');
    return '' if not(defined($condition));
    if (($condition->{'att'}->{'k'} eq 'poi')
      || ($condition->{'att'}->{'k'} eq 'rendering'))
    {
      return $condition->{'att'}->{'v'};
    }
}

    foreach my $entry (sort {entry_name($a) cmp entry_name($b) } @rule)
     {
       my $name = 'unknown';
       my $condition=$entry->last_child('condition');
       next if not(defined($condition));
       if (($condition->{'att'}->{'k'} eq 'poi')
         || ($condition->{'att'}->{'k'} eq 'rendering'))
       {
         $name = $condition->{'att'}->{'v'};
       }

       next if not($opt_i) && $name =~ m/^incomming/;

       $entry->print;
       print "\n"; 
     }
    print "</rules>\n";
  close TMPFILE;

  # Create backup copy of old XML-File
  #
  #move("$file_xml","$file_xml.bak") or die (" Couldn't create backup file!");
  move("./icons.tmp","$file_xml") or die (" Couldn't remove temp file!");
  print STDOUT "\n XML-File successfully updated!\n";

  $twig->purge;

  return;

  # look, if POI-Type already exists in the file by checking for a
  # known name inside the condition tag. If true, kick it from the icons
  # hash, because it's not needed anymore.
  sub sub_condition
   {
     my( $twig, $condition)= @_;

     if (($condition->{'att'}->{'k'} eq 'poi')
       || ($condition->{'att'}->{'k'} eq 'rendering'))
     {
       my $name = $condition->{'att'}->{'v'};
       if (exists $ICONS{$name}) 
       {
         print STDOUT "  o  \t$name\n" if $VERBOSE;
         delete $ICONS{"$name"};
       }
     }
   }
}


#####################################################################
#
#  Insert new POI-Type into the file
#
#
sub insert_poi_type
{
  my $name = shift(@_);
  my $twig_root = shift(@_);

  my $new_rule = new XML::Twig::Elt( 'rule');
 
  my $new_condition = new XML::Twig::Elt('condition');
  if ($name =~ m/^rendering/)
    { $new_condition->set_att(k=>'rendering'); }
  else
    { $new_condition->set_att(k=>'poi'); }
  $new_condition->set_att(v=>"$name");
  my $new_title_en = new XML::Twig::Elt('title',$default_title_en);
  $new_title_en->set_att(lang=>'en');
  my $new_desc_en = new XML::Twig::Elt('description',$default_desc_en);
  $new_desc_en->set_att(lang=>'en');
  my $new_scale_min = new XML::Twig::Elt('scale_min',$default_scale_min);
  my $new_scale_max = new XML::Twig::Elt('scale_max',$default_scale_max);

  $new_desc_en->paste('first_child',$new_rule);
  $new_title_en->paste('first_child',$new_rule);
  $new_scale_max->paste('first_child',$new_rule);
  $new_scale_min->paste('first_child',$new_rule);
  $new_condition->paste('first_child',$new_rule);

  $new_rule->paste('last_child',$$twig_root); 

  print STDOUT "  +  \t$name\n" if $VERBOSE;
}


#####################################################################
#
#  Get all the available icons in data/icons
#
#
sub get_icons
{
  print STDOUT "\n----- Looking for available icons -----\n";
  $i = 0;
  find( \&format_icons,  @ALL_TYPES );
  sub format_icons()
  { 
      my $icon_file = $File::Find::name;
      if ( $icon_file =~ m/\.svn/ ) {
      } elsif ( not($opt_i) && $icon_file =~ m/incomming/ ) {
	  print STDOUT "ignore incomming: $icon_file\n" if $VERBOSE;
      } elsif ( $icon_file =~ m/\.(png|svg)$/ && $icon_file !~ m/empty\.(png|svg)$/ ) {
	  $i++;
	  print STDOUT "  Found icon:\t$i\t$icon_file\n" if $VERBOSE;
	  for my $type ( @ALL_TYPES ) {
	      $icon_file =~ s,^$type/,,g;
	  }
	  $icon_file =~ s,\.(png|svg)$,,g;
	  $icon_file =~ s,/,.,g;
	  $ICONS{"$icon_file"} = '1';
      }
  }
  delete $ICONS{''} if (exists $ICONS{''});
  print STDOUT " $i icons for ".keys(%ICONS)." POI-Types found in data/map-icons\n";
  
}

#####################################################################
#
#  Create a new XML File and fill it with the basic POI-Types
#
#
sub create_xml
 { 
   print STDOUT "\n----- Creating new basic XML-File \"$file_xml\" -----\n";
   print STDOUT "\n  ATTENTION: It is possible, that the IDs will change,\n";
   print STDOUT "\n  so it would be better, if you update an existing icons.xml!\n";
   my @poi_types = (

     { name => 'unknown',
       scale_min => '1',
       scale_max => '50000',
       description_en => 'Unassigned POI',
       description_de => 'Nicht zugewiesener POI',
       title_en => 'Unknown',
       title_de => 'Unbekannt',
     },
     { name => 'accommodation',
       scale_min => '1',
       scale_max => '50000',
       description_en => 'Places to stay',
       description_de => 'Hotels, Jugendherbergen, Campingpl&#228;tze',
       title_en => 'Accommodation',
       title_de => 'Unterkunft',
     },
     { name => 'education',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Schools and other educational facilities',
       description_de => 'Schulen und andere Bildungseinrichtungen',
       title_en => 'Education',
       title_de => 'Bildung',
     },
     { name => 'food',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Restaurants, Bars, and so on...',
       description_de => 'Restaurants, Bars, usw.',
       title_en => 'Food',
       title_de => 'Speiselokal',
     },
     { name => 'geocache',
       scale_min => '1',
       scale_max => '50000',
       description_en => 'Geocaches',
       description_de => 'Geocaches',
       title_en => 'Geocache',
       title_de => 'Geocache',
     },
     { name => 'health',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Hospital, Doctor, Pharmacy, etc.',
       description_de => 'Krankenh&#228;user, &#196;rzte, Apotheken',
       title_en => 'Health',
       title_de => 'Gesundheit',
     },
     { name => 'money',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Bank, ATMs, and other money-related places',
       description_de => 'Banken, Geldautomaten, und &#228;hnliches',
       title_en => 'Money',
       title_de => 'Geld',
     },
     { name => 'nautical',
       scale_min => '1',
       scale_max => '50000',
       description_en => 'Special aeronautical Points',
       description_de => 'Spezielle aeronautische Punkte',
       title_en => 'aeronautical',
       title_de => 'aeronautisch',
     },
     { name => 'people',
       scale_min => '1',
       scale_max => '50000',
       description_en => 'Your home, work, friends, and other people',
       description_de => 'Dein Zuhause, die Arbeitsstelle, Freunde, und andere Personen',
       title_en => 'People',
       title_de => 'Person',
     },
     { name => 'places',
       scale_min => '10000',
       scale_max => '500000',
       description_en => 'Settlements, Mountains, and other geographical stuff',
       description_de => 'Siedlungen, Berggipfel, und anderes geografisches Zeug',
       title_en => 'Place',
       title_de => 'Ort',
     },
     { name => 'public',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Public facilities and Administration',
       description_de => 'Verwaltung und andere &#246;ffentliche Einrichtungen',

       title_en => 'Public',
       title_de => '&#214;ffentlich',
     },
     { name => 'recreation',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Places used for recreation (no sports)',
       description_de => 'Freizeiteinrichtungen (kein Sport)',
       title_en => 'Recreation',
       title_de => 'Freizeit',
     },
     { name => 'religion',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Places and facilities related to religion',
       description_de => 'Kirchen und andere religi&#246;se Einrichtungen',
       title_en => 'Religion',
       title_de => 'Religion',
     },
     { name => 'shopping',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'All the places, where you can buy something',
       description_de => 'Orte, an denen man etwas k&#228;uflich erwerben kann',
       title_en => 'Shopping',
       title_de => 'Einkaufen',
     },
     { name => 'sightseeing',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Historic places and other interesting buildings',
       description_de => 'Historische Orte und andere interessante Bauwerke',
       title_en => 'Sightseeing',
       title_de => 'Sehensw&#252;rdigkeit',
     },
     { name => 'sports',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Sports clubs, stadiums, and other sports facilities',
       description_de => 'Sportpl&#228;tze und andere sportliche Einrichtungen',
       title_en => 'Sports',
       title_de => 'Sport',
     },
     { name => 'transport',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Airports and public transportation',
       description_de => 'Flugh&#228;fen und &#246;ffentliche Transportmittel',
       title_en => 'Public Transport',
       title_de => '&#214;ffentliches Transportmittel',
     },
     { name => 'vehicle',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'Facilites for drivers, like gas stations or parking places',
       description_de => 'Dinge f&#252;r Selbstfahrer, z.B. Tankstellen oder Parkpl&#228;tze',
       title_en => 'Vehicle',
       title_de => 'Fahrzeug',
     },
     { name => 'wlan',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'WiFi-related points (Kismet)',
       description_de => 'Accesspoints und andere WLAN-Einrichtungen (Kismet)',
       title_en => 'WLAN',
       title_de => 'WLAN',
     },
     { name => 'misc',
       scale_min => '1',
       scale_max => '25000',
       description_en => 'POIs not suitable for another category, and custom types',
       description_de => 'Eigenkreationen, und Punkte, die in keine der anderen Kategorien passen',
       title_en => 'Miscellaneous',
       title_de => 'Verschiedenes',
     },
     { name => 'waypoint',
       scale_min => '1',
       scale_max => '50000',
       description_en => 'Waypoints, for example  to temporarily mark several places',
       description_de => 'Wegpunkte, um z.B. temporäre Punkte zu markieren',
       title_en => 'Waypoint',
       title_de => 'Wegpunkt',
     },
    
   );

   open NEWFILE,">:utf8","./$file_xml";
   select NEWFILE;

   print"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
   print"<rules>\n\n";
   foreach (@poi_types)
     {
       print"  <rule>\n";
       print"    <condition k=\"poi\" v=\"$$_{'name'}\" />\n";
       print"    <scale_min>$$_{'scale_min'}</scale_min>\n";
       print"    <scale_max>$$_{'scale_max'}</scale_max>\n";
       print"    <title lang=\"de\">$$_{'title_de'}</title>\n";
       print"    <title lang=\"en\">$$_{'title_en'}</title>\n";
       print"    <description lang=\"de\">$$_{'description_de'}</description>\n";
       print"    <description lang=\"en\">$$_{'description_en'}</description>\n";
       print"  </rule>\n\n";
       print STDOUT "  +  \t$$_{'name'}\n" if $VERBOSE;
     }
   print "</rules>\n";
 
   close NEWFILE;

   if (-e $file_xml)
     { print STDOUT " New XML-File \"$file_xml\" successfully created!\n"; }
   else
     { die " ERROR: Failed in creating new XML-File \"$file_xml\" !\n"; }

 }


__END__


=head1 SYNOPSIS
 
update_icons.pl [-h] [-v] [-i] [-r] [-f XML-FILE]
 
=head1 OPTIONS
 
=over 2
 
=item B<--h>

 Show this help

=item B<-f> XML-FILE

 Set file, that holds all the necessary icon and poi_type information.
 The default file is 'icons.xml'.

=item B<-v>

 Enable verbose output

=back
