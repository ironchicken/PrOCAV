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

package Database;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(make_dbh get_record insert_record find_look_up registered_look_ups table_info table_order);

my %db_attrs = (RaiseError  => 1,
		PrintError  => 0);

my %db_opts = (database => "DBI:mysql:procav",
	       user     => "root",
	       password => "tbatst",
	       attrs    => \%db_attrs);

sub make_dbh {
    DBI->connect($db_opts{database},
		 $db_opts{user},
		 $db_opts{password})
	or die ("Could not connect to database.\n");
}

# Named look-ups. 
my %look_ups = (
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

    performance_types    => sub { [{value => "concert", display => "Concert"},
				   {value => "broadcast", display => "Broadcast"},
				   {value => "recording", display => "Recording"},
				   {value => "private", display => "Private"}]; },

    mentionable_tables   => sub { [{value => "works", display => "Works"},
				   {value => "titles", display => "Titles"},
				   {value => "composition", display => "Composition"},
				   {value => "editions", display => "Editions"},
				   {value => "publications", display => "Publications"},
				   {value => "performances", display => "Performances"},
				   {value => "letters", display => "Letters"},
				   {value => "manuscripts", display => "Manuscripts"},
				   {value => "texts", display => "Texts"},
				   {value => "dedicated_to", display => "Dedicated_to"}]; },

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
				  $dbh->prepare(qq(SELECT DISTINCT genre AS value, genre AS display FROM genres ORDER BY genre)); },

    instruments          => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT DISTINCT instrument AS value, instrument AS display FROM instruments ORDER BY instrument)); },

    manuscripts          => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT manuscripts.ID AS value, title AS display FROM manuscripts ORDER BY title)); },

    editions             => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT editions.ID AS value, CONCAT(title, " (", publication_range, ")") AS display FROM editions JOIN published_in ON editions.ID=edition_id JOIN publications ON publications.ID=publication_id ORDER BY title)); },

    publications         => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT publications.ID AS value, title AS display FROM publications ORDER BY title)); },

    persons              => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT persons.ID AS value, CONCAT(family_name, ", ", given_name) AS display FROM persons ORDER BY family_name, given_name)); },

    score_types          => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT DISTINCT score_type AS value, score_type AS display FROM editions ORDER BY score_type)); },

    performances         => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT performances.ID AS value, CONCAT(works.uniform_title, " ", dates.day, "/", dates.month, "/", dates.year) AS display FROM performances JOIN works ON performances.work_id=works.ID JOIN dates ON performances.date_performed=dates.ID ORDER BY works.uniform_title, dates.year, dates.month, dates.day)); }

    );

sub registered_look_ups {
    keys %look_ups;
}

sub find_look_up {
    my $look_up_name = shift;
    $look_ups{$look_up_name};
}

# FIXME Think about all the properties a field will need. For example,
# when a new work is added to the spreadsheet, its uniform_title will
# need to be available to any spreadsheet cell which provides a
# uniform_title lookup. The implication is that fields need "accessor
# methods" which should be functions to be executed by the
# spreadsheet. A solution could be that the look-up cells use the
# uniform_titles column of the "works" worksheet, plus a pre-defined
# list of uniform_titles taken from the database.

my @table_order = qw(works titles composition instruments genres manuscripts editions publications published_in performances performed_in letters texts persons);

sub table_order {
    @table_order;
}

my %schema = (
    works => {
	_worksheet => "works",
	_field_order => [qw(ID catalogue_no uniform_title sub_title part_of parent_relation opus_number opus_suffix status genres duration notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 2},
	catalogue_no    => {access => "rw",
			    data_type => "string",
			    cell_width => 3},
	uniform_title   => {access => "rw",
			    data_type => "string",
			    not_null => 1,
			    cell_width => 5},
	sub_title       => {access => "rw",
			    data_type => "string",
			    cell_width => 5},
	part_of         => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    list_mutable => 0,
			    cell_width => 5},
	parent_relation => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_relation",
			    list_mutable => 0,
			    cell_width => 5},
	opus_number     => {access => "rw",
			    data_type => "integer",
			    cell_width => 2},
	opus_suffix     => {access => "rw",
			    data_type => "string",
			    cell_width => 2},
	status          => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_status",
			    list_mutable => 0,
			    list_insert => qq(INSERT INTO work_status (work_id, status) VALUES (?,?)),
			    cell_width => 3},
	genres          => {access => "rw",
			    data_type => "look_up",
			    look_up => "genres",
			    list_mutable => 1,
			    list_insert => qq(INSERT INTO genres (work_id, genre) VALUES (?,?)),
			    cell_width => 5},
	duration        => {access => "rw",
	  		    data_type => "float",
			    cell_width => 2},
	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 10}},
    titles => {
	_worksheet => "titles",
	_field_order => [qw(ID work_id manuscript_id edition_id person_id title transliteration script language notes)],

	ID              => {access => "ro",
			    primary_key => 1},
	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1},
	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => "manuscripts"},
	edition_id      => {access => "rw",
			    data_type => "look_up",
			    look_up => "editions"},
	person_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons"},
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
	_field_order => [qw(work_id instrument role)],

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1},
	instrument      => {access => "rw",
	 		    data_type => "look_up",
			    look_up => "instruments",
	 		    list_mutable => 1,
			    not_null => 1},
	role            => {access => "rw",
			    data_type => "string"}},

    derived_from       => {
	_worksheet => "derived_from",
	_field_order => [qw(precusor_work derived_work derivation_relation)],

	precusor_work   => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    list_mutable => 0,
			    not_null => 1},
	derived_work    => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    list_mutable => 0,
			    not_null => 1},
	
	derivation_relation => {access => "rw",
				data_type => "look_up",
				look_up => "derivation_relations",
				not_null => 1}},

    composition        => {
	_worksheet => "composition",
	_field_order => [qw(work_id manuscript_id period_start work_type)],

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    not_null => 1},

	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => "manuscripts",
			    not_null => 1},

	period_start    => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	work_type       => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_types"}},

    editions           => {
	_worksheet => "editions",
	_field_order => [qw(ID work_id date_made editor score_type work_extent notes)],

	
	ID              => {access => "ro",
			    primary_key => 1},

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1},

	date_made       => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	editor          => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons"},

	score_type      => {access => "rw",
			    data_type => "look_up",
			    look_up => "score_types",
	 		    list_mutable => 1},
	work_extent     => {access => "rw",
			    data_type => "string"},

	notes           => {access => "rw",
			    data_type => "string"}},

    publications       => {
	_worksheet => "publications",
	_field_order => [qw(ID title publisher publication_place date_published serial_number notes)],

	ID              => {access => "ro",
			    primary_key => 1},

	title           => {access => "rw",
			    data_type => "string",
			    not_null => 1},

	publisher       => {access => "rw",
			    data_type => "string"},

	publication_place => {access => "rw",
			      data_type => "string"},

	date_published  => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	serial_number   => {access => "rw",
			    data_type => "string"},

	notes           => {access => "rw",
			    data_type => "string"}},

    published_in       => {
	_worksheet => "published_in",
	_field_order => [qw(edition_id publication_id edition_extent publication_range)],

	edition_id      => {access => "rw",
			    data_type => "look_up",
			    look_up => "editions",
			    not_null => 1},

	publication_id  => {access => "rw",
			    data_type => "look_up",
			    look_up => "publications",
			    not_null => 1},

	edition_extent  => {access => "rw",
			    data_type => "string"},

	publication_range => {access => "rw",
			      data_type => "string"}},

    performances       => {
	_worksheet => "performances",
	_field_order => [qw(ID work_id date_performed venue_id performance_type notes)],

	ID              => {access => "ro",
			    primary_key => 1},

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1},

	date_performed  => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	venue_id        => {access => "rw",
			    data_type => "integer"},

	performance_type => {access => "rw",
			     data_type => "look_up",
			     look_up => "performance_types"},

	notes           => {access => "rw",
			    data_type => "string"}},

    performed_in       => {
	_worksheet => "performed_in",
	_field_order => [qw(person_id performance_id role)],

	person_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    not_null => 1},

	performance_id  => {access => "rw",
			    data_type => "look_up",
			    look_up => "performances",
			    not_null => 1},

	role            => {access => "rw",
			    data_type => "string"}},

    letters            => {
	_worksheet => "letters",
	_field_order => [qw(ID letters_db_ID date_composed date_sent addressee signatory original_text english_text)],

	ID              => {access => "ro",
			    primary_key => 1},

	letters_db_ID   => {access => "rw",
			    data_type => "string"},

	date_composed   => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	date_sent       => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_approx, month_approx, day_approx, end_year, end_month, end_day, end_year_approx, end_month_approx, end_day_approx) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	addressee       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons"},

	signatory       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons"},

	original_text   => {access => "rw",
			    data_type => "string"},

	english_text    => {access => "rw",
			    data_type => "string"}},

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

sub table_info {
    my $table_name = shift;
    $schema{$table_name};
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
