#!/usr/bin/perl
# Create SQLite Database file used by GpsDrive
# Fill it with:
#   - POI Sources predefined in this script
#   - POI Types as defined in icons.xml
#   TODO: - Field Types for additional POI Information (poi_extra)

########################################################################################

my $default_lang  = 'en';
my $default_licence = 'Creative Commons Attribution-ShareAlike 2.0';

########################################################################################

# Get version number from version-control system, as integer 
my $version = '$Revision: 1824 $';
$Version =~ s/\$Revision:\s*(\d+)\s*\$/$1/;
 
my $VERSION ="create_geoinfo-db.pl (c) Guenther Meyer
Version 0.1-$Version";

use strict;
use warnings;

use DBI;
use File::Copy;
use XML::Twig;
use Getopt::Long;
use Pod::Usage;

my $lang;
my $db_file;
my $dbh;
my ($man,$help,$DEBUG,$VERBOSE)=(0,0,0,0);

my $icons_xml= "./icons.xml";

########################################################################################
# Execute SQL statement
#
sub db_exec($){
    my $statement = shift;

    my $sth = $dbh->prepare($statement);
    unless ( $sth->execute() ) {
        warn "Error in query '$statement'\n";
        $sth->errstr;
        return 0;
    }
    return 1;
}


########################################################################################
# Creata db file and tables
#
sub create_dbfile(){
    my $create_statement;
    my $sth;

    move("$db_file","$db_file.old");

    $create_statement="CREATE DATABASE geoinfo;";
    $dbh = DBI->connect("dbi:SQLite:dbname=$db_file",'','');
    $dbh->{unicode} = 1;

    # ------- POI_TYPE
    db_exec('CREATE TABLE poi_type (
		poi_type       VARCHAR(160)  PRIMARY KEY,
		scale_min      INTEGER       NOT NULL default \'1\',
		scale_max      INTEGER       NOT NULL default \'50000\',
		title          VARCHAR(160)  NULL default \'\',
		description    VARCHAR(160)  NULL default \'\');') or die;

     # ------- SOURCE
    db_exec('CREATE TABLE source (
		source_id      INTEGER      PRIMARY KEY,
		name           VARCHAR(80)  NOT NULL default \'\',
		comment        VARCHAR(160) NOT NULL default \'\',
		last_update    DATE         NOT NULL default \'0000-00-00\',
		url            VARCHAR(160) NOT NULL default \'\',
		licence        VARCHAR(160) NOT NULL default \'\');') or die;
 
}


########################################################################################
# Fill poi_type table
#
sub fill_default_poi_types(;$) {
    my $i=1;
    my $used_icons ={};

    my $unused_icon ={};
    my $existing_icon ={};

    my $icon_file=shift;
    $icon_file = '../data/map-icons/icons.xml'          unless -s $icon_file;
    $icon_file = '../share/map-icons/icons.xml'         unless -s $icon_file;
    $icon_file = '/usr/local/share/icons/map-icons/icons.xml' unless -s $icon_file;
    $icon_file = '/usr/local/share/map-icons/icons.xml' unless -s $icon_file;
    $icon_file = '/usr/share/icons/map-icons/icons.xml' unless -s $icon_file;
    $icon_file = '/usr/share/map-icons/icons.xml'       unless -s $icon_file;
    $icon_file = '/opt/gpsdrive/icons.xml'              unless -s $icon_file;
    die "no Icon File found" unless -s $icon_file;

    print "Using Icons File '$icon_file'\n" if $DEBUG || $VERBOSE;

    our $title = ''; our $title_en = '';
    our $description = ''; our $description_en = '';

    # parse icon file
    #
    my $twig= new XML::Twig
    (
       TwigHandlers => { rule        => \&sub_poi,
                         title       => \&sub_title,
                         description => \&sub_desc }
    );
    $twig->parsefile( "$icon_file");
    my $rules= $twig->root;

    $twig->purge;

    sub sub_poi
    {
      my ($twig, $poi_elm) = @_;
      if ($poi_elm->first_child('condition')->att('k') eq 'poi')
      {
        my $name = $poi_elm->first_child('condition')->att('v');
        my $scale_min = $poi_elm->first_child('scale_min')->text;
        my $scale_max = $poi_elm->first_child('scale_max')->text;
        $title = $title_en unless ($title);
	$description = $description_en unless ($description);

	# replace ' by something else, because otherwise the sql statement wil fail
	#$description =~ s/'/&#0039;/g;
	$description =~ s/'/&apos;/g;

	print "Adding POI: $name\n" if $VERBOSE;
	print "            $title - $description\n"  if $VERBOSE > 1;

	db_exec(
	  "INSERT INTO `poi_type` ".
          "(poi_type, scale_min, scale_max, title, description) ".
	  "VALUES ('$name','$scale_min','$scale_max','$title','$description');") 
	    or die "Insert of poi_type Failed ('$name','$scale_min','$scale_max','$title','$description')\n";
      }
      $title = ''; $title_en = '';
      $description = ''; $description_en = '';
    }

    sub sub_title
    {
      my ($twig, $title_elm) = @_;
      if ($title_elm->att('lang') eq 'en')
        { $title_en = $title_elm->text; }
      elsif ($title_elm->att('lang') eq $lang)
        { $title = $title_elm->text; }
    }

    sub sub_desc
    {
      my ($twig, $desc_elm) = @_;
      if ($desc_elm->att('lang') eq 'en')
        { $description_en = $desc_elm->text; }
      elsif ($desc_elm->att('lang') eq $lang)
        { $description = $desc_elm->text; }
    }
}


########################################################################################
# Fill source table
#
sub fill_default_sources() {   # Just some Default Sources

    my @sources = (
      { source_id   => '1',
        name        => 'unknown',
        comment     => 'Unknown source or source not defined', 
        last_update => '2008-03-01',
        url         => 'http://www.gpsdrive.de/',
        licence     => 'unknown'
      },
      { source_id   => '2',
        name        => 'way.txt',
        comment     => 'Data imported from way.txt', 
        last_update => '2008-03-01',
        url         => 'http://www.gpsdrive.de/',
        licence     => 'unknown'
      },
      { source_id   => '3',
        name        => 'user',
	comment     => 'Data entered by the GpsDrive-User',
	last_update => '2008-03-01',
	url         => 'http://www.gpsdrive.cc/',
	licence     => $default_licence
      },
      { source_id   => '4',
        name        => 'OpenStreetMap.org',
        comment     => 'General Data imported from the OpenStreetMap Project', 
        last_update => '2007-01-03',
        url         => 'http://www.openstreetmap.org/',
        licence     => 'Creative Commons Attribution-ShareAlike 2.0'
      },
      { source_id   => '5',
        name        => 'groundspeak',
        comment     => 'Geocache data from Groundspeak', 
        last_update => '2007-01-30',
        url         => 'http://www.groundspeak.com/',
        licence     => 'unknown'
      },
      { source_id   => '6',
        name        => 'opencaching',
        comment     => 'Geocache data from Opencaching', 
        last_update => '2007-09-30',
        url         => 'http://www.opencaching.de/',
        licence     => 'unknown'
      },
      
      { source_id   => '7',
        name        => 'friendsd',
        comment     => 'Position received from friendsd server', 
        last_update => '2007-09-30',
        url         => 'http://friendsd.gpsdrive.de/',
        licence     => 'none'
      },
      { source_id   => '8',
        name        => 'fon',
        comment     => 'Access point data from FON', 
        last_update => '2007-09-30',
        url         => 'http://www.fon.com/',
        licence     => 'unknown'
      },
      { source_id   => '9',
        name        => 'kismet',
        comment     => 'Access point data found by Kismet', 
        last_update => '2008-03-01',
        url         => 'http://www.kismetwireless.net/',
        licence     => 'unknown'
      },
      { source_id   => '10',
        name        => 'postgis',
        comment     => 'Data read from a local mapnik/postgis database', 
        last_update => '2008-03-11',
        url         => 'http://www.openstreetmap.org/',
        licence     => 'Creative Commons Attribution-ShareAlike 2.0'
      },
    );

      print "Adding Sources:\n";
    foreach (@sources) {
      print "	Adding Source: $$_{'name'} - $$_{'url'}\n" if $VERBOSE;
      db_exec(
        "INSERT INTO `source` ".
          "(source_id, name, comment, last_update, url, licence) ".
	  "VALUES ($$_{'source_id'},'$$_{'name'}','$$_{'comment'}',".
	  "'$$_{'last_update'}','$$_{'url'}','$$_{'licence'}');") or die;
    }

}


########################################################################################
#
#                     Main
#
########################################################################################

# Set defaults and get options from command line
Getopt::Long::Configure('no_ignore_case');
GetOptions ( 'lang=s'      => \$lang,
	     'icons_xml=s' => \$icons_xml,
	     'db_file=s'   => \$db_file,
	     'd+'          => \$DEBUG,
	     'debug+'      => \$DEBUG,      
	     'verbose'     => \$VERBOSE,
	     'v+'          => \$VERBOSE,
	     'h|help|x'    => \$help, 
	     'MAN'         => \$man, 
	     'man'         => \$man, 
    )
    or pod2usage(1);

pod2usage(1) if $help;
pod2usage(-verbose=>2) if $man;

$lang = $lang || $default_lang;

if ($lang eq 'en')
  { $db_file ||= "./geoinfo.db"; }
else
  { $db_file ||= "./geoinfo.$lang.db"; }

print "$VERSION\n";

create_dbfile();
fill_default_sources();
fill_default_poi_types($icons_xml);


__END__

=head1 NAME

B<create_geoinfo-db.pl> Version 0.1

=head1 DESCRIPTION

Create SQLite Database file used by GpsDrive
Fill it with:
   - POI Sources predefined in this script
   - POI Types as defined in icons.xml
   TODO: - Field Types for additional POI Information (poi_extra)

=item B<--man>

Print this small usage

=item B<-d>

Add some more Debug Output

=item B<-v>

Some more Otput while creating

=item B<icons_xml>

Icons.xml File (default ./icons.xml)

=item B<db_file>

the resulting geoinfo.db File (default ./geoinfo.db | geoinfo.de.db)

=back
