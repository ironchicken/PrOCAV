#
# PrOCAV
#
# This module provides prepared statements and other useful functions
# for working with the PrOCAV database.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use DBI;
use base 'Exporter';

package Database;

our @EXPORT = qw(make_dbh get_record insert_record);
our @EXPORT_OK = qw(look_ups schema);

my %db_attrs = (RaiseError  => 1,
		PrintError  => 0);

my %db_opts = (database => "DBI:mysql:procav",
	       user     => "root",
	       password => "tbatst",
	       attrs    => \%db_attrs);

sub make_dbh {
    DBI->connect($db_opts{database},
		 $db_opts{user},
		 $db_opts{password});
}

# Named look-ups. 
our %look_ups = (
    # The first values in this hash are subroutines which return a
    # list of hashes containing `value` and `display` fields. (They
    # are subroutines in order to be polymorphic with the other items
    # in the hash.)
    parent_relation      => sub { [{value => "movement", display => "Movement"},
				   {value => "act",      display => "Act"},
				   {value => "scene",    display => "Scene"},
				   {value => "number",   display => "Number"}]; },

    work_status          => sub { [{value => "juvenilia",   display => "Juvenilia"},
				   {value => "incomplete",  display => "Incomplete"},
				   {value => "unpublished", display => "Unpublished"},
				   {value => "published",   display => "Published"}] },

    derivation_relations => sub { [{value => "transcription", display => "Transcription"},
				   {value => "arrangement",   display => "Arrangement"},
				   {value => "off-shoot",     display => "Off-shoot"}]; },

    work_types           => sub { [{value => "sketch",                        display => "Sketch"},
				   {value => "contextualised sketch",         display => "Contextualised sketch"},
				   {value => "draft short/piano score",       display => "Draft short/piano score"},
				   {value => "extended draft short score",    display => "Extended draft short score"},
				   {value => "instrumental annotations",      display => "Instrumental annotations"},
				   {value => "autograph complete full score", display => "Autograph complete full score"}]; },

    # Each of the rest of values in this hash is a subroutine
    # reference which should be called with a database handle as an
    # argument. It then returns a prepared statement which SELECTs
    # rows containing `value` and `display` fields. These results sets
    # can be used as look-ups.
    parent_works         => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT works.ID AS value, CONCAT(uniform_title, IFNULL(CONCAT(" Op. ", opus_number),""), IFNULL(opus_suffix,"")) AS display FROM works WHERE part_of IS NULL ORDER BY uniform_title)); },

    all_works            => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT works.ID AS value, CONCAT(uniform_title, IFNULL(CONCAT(" Op. ", opus_number),""), IFNULL(opus_suffix,"")) AS display FROM works ORDER BY uniform_title)); },

    genres               => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT DISTINCT genre FROM genres ORDER BY genre)); },

    instruments          => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT DISTINCT instrument FROM instruments ORDER BY instrument)); },

    manuscripts          => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT manuscripts.ID AS value, title AS display FROM manuscripts ORDER BY title)); },

    editions             => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT editions.ID AS value, CONCAT(title, " (", publication_range, ")") AS display FROM editions JOIN published_in ON editions.ID=edition_id JOIN publications ON publications.ID=publication_id ORDER BY title)); },

    persons              => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT persons.ID AS value, CONCAT(family_name, ", ", given_name) AS display FROM persons ORDER BY family_name, given_name)); },

    );

# FIXME Think about all the properties a field will need. For example,
# when a new work is added to the spreadsheet, its uniform_title will
# need to be available to any spreadsheet cell which provides a
# uniform_title lookup. The implication is that fields need "accessor
# methods" which should be functions to be executed by the
# spreadsheet. A solution could be that the look-up cells use the
# uniform_titles column of the "works" worksheet, plus a pre-defined
# list of uniform_titles taken from the database.

our %schema = (
    works => {
	_worksheet => "works",

	ID              => {access => "ro",
			    primary_key => 1},
	catalogue_no    => {access => "rw",
			    data_type => "string"},
	uniform_title   => {access => "rw",
			    data_type => "string",
			    not_null => 1},
	sub_title       => {access => "rw",
			    data_type => "string"},
	part_of         => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{parent_works},
			    list_mutable => 0},
	parent_relation => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{parent_relation},
			    list_mutable => 0},
	opus_number     => {access => "rw",
			    data_type => "integer"},
	opus_suffix     => {access => "rw",
			    data_type => "string"},
	status          => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{work_status},
			    list_mutable => 0,
			    list_insert => qq(INSERT INTO work_status (work_id, status) VALUES (?,?))},
	genres          => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{genres},
			    list_mutable => 1,
			    list_insert => qq(INSERT INTO genres (work_id, genre) VALUES (?,?))},
	duration        => {access => "rw",
	  		    data_type => "float"},
	notes           => {access => "rw",
			    data_type => "string"}},
    titles => {
	_worksheet => "titles",

	ID              => {access => "ro",
			    primary_key => 1},
	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{all_works},
			    not_null => 1},
	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{manuscripts}},
	edition_id      => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{editions}},
	person_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{persons}},
	title           => {access => "rw",
			    data_type => "string"},
	transliteration => {access => "rw",
			    data_type => "string"},
	script          => {access => "rw",
			    data_type => "string"},
	language        => {access => "rw",
			    data_type => "string"},
	notes           => {access => "rw",
			    data_type => "string"}},

    work_status        => {},
    genres             => {},

    instruments        => {
	_worksheet => "instruments",

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{all_works},
			    not_null => 1},
	instrument      => {access => "rw",
	 		    data_type => "look_up",
			    look_up => $look_ups{instruments},
	 		    list_mutable => 1,
			    not_null => 1},
	role            => {access => "rw",
			    data_type => "string"}},

    derived_from       => {
	_worksheet => "derived_from",

	precusor_work   => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{parent_works},
			    list_mutable => 0,
			    not_null => 1},
	derived_work    => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{parent_works},
			    list_mutable => 0,
			    not_null => 1},
	
	derivation_relation => {access => "rw",
				data_type => "look_up",
				look_up => $look_ups{derivation_relations},
				not_null => 1}},

    composition        => {
	_worksheet => "composition",

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{parent_works},
			    not_null => 1},

	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{manuscripts},
			    not_null => 1},

	period_start    => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	work_type       => {access => "rw",
			    data_type => "look_up",
			    look_up => $look_ups{work_types}}},

    editions           => {},
    publications       => {},
    published_in       => {},
    performances       => {},
    performed_in       => {},
    letters            => {},
    letter_mentions    => {},
    manuscripts        => {},
    texts              => {},
    persons            => {},
    dedicated_to       => {},
    dates              => {},
    media_items        => {},
    remote_media_items => {},
    representation_of  => {},
    resources          => {},
    resource_about     => {});

sub look_up_sql {

}

sub look_up_list {

}

sub get_record {
    my ($table, $ID) = @_;

    my $proc = $schema{$table}->{get};

    if (defined $proc) {
	return $proc->($ID);
    } else {
	warn("No get record procedure for $table.\n");
    }
}

sub insert_record { }


sub insert_work { }

sub get_works_list {
    my $dbh = shift;

    my $works_list_stmt = $dbh->prepare(qq(SELECT * FROM works WHERE part_of IS NULL));
}

sub get_work {
    my $dbh = shift;

    if (@_) {
	my $work_id = shift;
 
	my $get_work_stmt = $dbh->prepare(qq(SELECT * FROM works WHERE ID=?));

	$get_work_stmt->execute($work_id);
	my @work = $get_work_stmt->fetchrow_array;

	if (@work) {
	    
	}
    }
}

1;
