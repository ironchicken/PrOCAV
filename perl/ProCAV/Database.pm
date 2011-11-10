#
# PrOCAV
#
# This modules provides prepared statements and other useful functions
# for working with the PrOCAV database.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use DBI;

package Database;

my %db_attrs = (RaiseError  => 1,
		PrintError  => 0);

my %db_opts = (user     => "root",
	    password => "tbatst",
            database => "procav",
	    attrs    => \%db_attrs);

sub look_up_sql {

}

sub look_up_list {

}

# FIXME Think about all the properties a field will need. For example,
# when a new work is added to the spreadsheet, its uniform_title will
# need to be available to any spreadsheet cell which provides a
# uniform_title lookup. The implication is that fields need "accessor
# methods" which should be functions to be executed by the
# spreadsheet. A solution could be that the look-up cells use the
# uniform_titles column of the "works" worksheet, plus a pre-defined
# list of uniform_titles taken from the database.

my %schema = (
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
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(opus_number, opus_suffix, uniform_title) AS display FROM works WHERE part_of IS NULL ORDER BY uniform_title/),
			    list_mutable => 0},
	parent_relation => {access => "rw",
			    data_type => look_up_list(qw/movement act scene number/),
			    list_mutable => 0},
	opus_number     => {access => "rw",
			    data_type => "integer"},
	opus_suffix     => {access => "rw",
			    data_type => "string"},
	status          => {access => "rw",
			    data_type => look_up_list(qw/juvenilia incomplete unpublished published/),
			    list_mutable => 0,
			    list_insert => qq/INSERT INTO work_status (work_id, status) VALUES (?,?)/},
	genres          => {access => "rw",
			    data_type => look_up_sql(qq/SELECT DISTINCT genre FROM genres ORDER BY genre/),
			    list_mutable => 1,
			    list_insert => qq/INSERT INTO genres (work_id, genre) VALUES (?,?)/},
	# instruments     => {access => "rw",
	# 		    data_type => look_up_sql(qq/SELECT DISTINCT instrument FROM instruments ORDER BY instrument/),
	# 		    list_mutable => 1,
	# 		    list_insert => qq/INSERT INTO instruments (work_id, instrument) VALUES (?,?)/},
	duration        => {access => "rw",
	  		    data_type => "float"},
	notes           => {access => "rw",
			    data_type => "string"}},
    titles => {
	_worksheet => "titles",

	ID              => {access => "ro",
			    primary_key => 1},
	work_id         => {access => "rw",
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(opus_number, opus_suffix, uniform_title) AS display FROM works WHERE part_of IS NULL ORDER BY uniform_title/),
			    not_null => 1},
	manuscript_id   => {access => "rw",
			    data_type => look_up_sql(qq/SELECT ID AS value, title AS display FROM manuscripts ORDER BY title/)},
	edition_id      => {access => "rw",
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(title, " (", publication_extent, ")") AS display FROM editions JOIN published_in ON editions.ID=edition_id JOIN publications ON publications.ID=publication_id ORDER BY title/)},
	person_id       => {access => "rw",
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(family_name, ", ", given_name) AS display FROM persons ORDER BY family_name, given_name/)},
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
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(opus_number, opus_suffix, uniform_title) AS display FROM works WHERE part_of IS NULL ORDER BY uniform_title/),
			    not_null => 1},
	instrument      => {access => "rw",
	 		    data_type => look_up_sql(qq/SELECT DISTINCT instrument FROM instruments ORDER BY instrument/),
	 		    list_mutable => 1,
			    not_null => 1},
	role            => {access => "rw",
			    data_type => "string"}},

    derived_from       => {
	_worksheet => "derived_from",

	precusor_work   => {access => "rw",
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(opus_number, opus_suffix, uniform_title) AS display FROM works WHERE part_of IS NULL ORDER BY uniform_title/),
			    list_mutable => 0,
			    not_null => 1},
	derived_work    => {access => "rw",
			    data_type => look_up_sql(qq/SELECT ID AS value, CONCAT(opus_number, opus_suffix, uniform_title) AS display FROM works WHERE part_of IS NULL ORDER BY uniform_title/),
			    list_mutable => 0,
			    not_null => 1},
	
	derivation_relation => {access => "rw",
				data_type => look_up_list(qw/transcription arrangement off-shoot/),
				not_null => 1}},

    composition        => {},
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
