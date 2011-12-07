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

    sex                  => sub { [{value => "male", display => "Male"},
				   {value => "female", display => "Female"}]; },

    date_source_tables   => sub { [{value => "editions", display => "Editions"},
				   {value => "letters", display => "Letters"},
				   {value => "manuscripts", display => "Manuscripts"}]; },

    pitch_classes        => sub { [{value => "C", display => "C"}, {value => "D", display => "D"},
				   {value => "E", display => "E"}, {value => "F", display => "F"},
				   {value => "G", display => "G"}, {value => "A", display => "A"},
				   {value => "B", display => "B"}]; },

    chromatics           => sub { [{value => "n", display => "Natural"}, {value => "b", display => "Flat"},
				   {value => "#", display => "Sharp"}]; },

    modes                => sub { [{value => "major", display => "Major"}, {value => "minor", display => "Minor"}]; },

    # FIXME Think about the logic of this; not after X is inclusive of
    # X, whereas before X is exclusive of X
    date_accuracy        => sub { [{value => "exactly", display => "Exactly"},
				   {value => "around", display => "Around"},
				   {value => "before", display => "Before"},
				   {value => "after", display => "After"}]; },

    # Each of the rest of values in this hash is a subroutine
    # reference which should be called with a database handle as an
    # argument. It then returns a prepared statement which SELECTs
    # rows containing `value` and `display` fields. These results sets
    # can be used as look-ups.
    parent_works         => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT works.ID AS value, CONCAT(uniform_title, IFNULL(CONCAT(" ", catalogues.label, number, IFNULL(suffix,"")),"")) AS display FROM works JOIN catalogue_number ON catalogue_number.work_id=works.ID JOIN catalogues ON catalogue_number.catalogue_id=catalogues.ID WHERE part_of IS NULL ORDER BY uniform_title)); },

    all_works            => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT works.ID AS value, CONCAT(uniform_title, IFNULL(CONCAT(" ", catalogues.label, number, IFNULL(suffix,"")),"")) AS display FROM works JOIN catalogue_number ON catalogue_number.work_id=works.ID JOIN catalogues ON catalogue_number.catalogue_id=catalogues.ID ORDER BY uniform_title)); },

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
				  $dbh->prepare(qq(SELECT performances.ID AS value, CONCAT(works.uniform_title, " ", dates.day, "/", dates.month, "/", dates.year) AS display FROM performances JOIN works ON performances.work_id=works.ID JOIN dates ON performances.date_performed=dates.ID ORDER BY works.uniform_title, dates.year, dates.month, dates.day)); },

    letters              => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT letters.ID AS value, CONCAT("From: ", s.given_name, " ", s.family_name, "; To: ", a.given_name, " ", a.family_name, "; Date: ", c.year, "/", c.month, "/", c.day) AS display FROM letters JOIN persons AS s ON letters.signatory = s.ID JOIN persons AS a ON letters.addressee = a.ID JOIN dates AS c ON c.ID = letters.date_composed ORDER BY c.year, c.month, c.day)); },

    catalogues           => sub { my $dbh = shift;
				  $dbh->prepare(qq(SELECT ID AS value, label AS display FROM catalogues ORDER BY label)); }

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

my @table_order = qw(works musical_information catalogue_numbers titles composition instruments genres work_status dedicated_to manuscripts editions publications published_in performances performed_in letters letter_mentions texts persons catalogues dates);

sub table_order {
    @table_order;
}

my %schema = (
    works => {
	_worksheet => "works",
	_field_order => [qw(ID catalogue_number uniform_title sub_title part_of parent_relation part_number part_position duration notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	catalogue_number => {access => "rw",
			     data_type => "string",
			     cell_width => 8},

	uniform_title   => {access => "rw",
			    data_type => "string",
			    not_null => 1,
			    cell_width => 20},

	sub_title       => {access => "rw",
			    data_type => "string",
			    cell_width => 20},

	part_of         => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    list_mutable => 0,
			    cell_width => 40},

	parent_relation => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_relation",
			    list_mutable => 0,
			    cell_width => 12},

	part_number     => {access => "rw",
			    data_type => "string",
			    width => 32,
			    documentation => "For sub-works, the number of this part"},

	part_position   => {access => "rw",
			    data_type => "integer",
			    documentation => "For sub-works, the parts will be ordered by this numerical value"},

	duration        => {access => "rw",
	  		    data_type => "decimal",
			    cell_width => 8},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    musical_information => {
	_worksheet => "musical_information",
	_field_order => [qw(work_id performance_direction tonic tonic_chromatic mode time_sig_beats time_sig_division)],

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	performance_direction => {access => "rw",
				  data_type => "string",
				  width => 128,
				  cell_width => 15},

	tonic           => {access => "rw",
			    data_type => "look_up",
			    look_up => "pitch_classes",
			    cell_width => 8},

	tonic_chromatic => {access => "rw",
			    data_type => "look_up",
			    look_up => "chromatics",
			    cell_width => 8},

	mode            => {access => "rw",
			    data_type => "look_up",
			    look_up => "modes",
			    cell_width => 8},

	time_sig_beats  => {access => "rw",
			    data_type => "integer",
			    cell_width => 8},

	time_sig_division => {access => "rw",
			      data_type => "integer",
			      cell_width => 8}},

    titles => {
	_worksheet => "titles",
	_field_order => [qw(ID work_id manuscript_id edition_id person_id title transliteration script language notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},
	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},
	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => "manuscripts",
			    cell_width => 30},
	edition_id      => {access => "rw",
			    data_type => "look_up",
			    look_up => "editions",
			    cell_width => 40},
	person_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    cell_width => 30},
	title           => {access => "rw",
			    data_type => "string",
			    cell_width => 20},
	transliteration => {access => "rw",
			    data_type => "string",
			    cell_width => 20},
	script          => {access => "rw",
			    data_type => "string",
			    cell_width => 10},
	language        => {access => "rw",
			    data_type => "string",
			    width => 2,
			    cell_width => 5},
	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    catalogue_numbers  => {
	_worksheet => "catalogue_numbers",
	_field_order => [qw(work_id catalogue_id number number_position suffix suffix_position)],

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	catalogue_id    => {access => "rw",
			    data_type => "look_up",
			    look_up => "catalogues",
			    not_null => 1,
			    cell_width => 20},

	number          => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8},

	number_position => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8},

	suffix          => {access => "rw",
			    data_type => "string",
			    width => 32,
			    cell_width => 8},

	suffix_position => {access => "rw",
			    data_type => "integer",
			    cell_width => 8}},
	
    work_status        => {
	_worksheet => "work_status",
	_field_order => [qw(work_id status)],

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},
	status          => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_status",
			    list_mutable => 0,
			    list_insert => qq(INSERT INTO work_status (work_id, status) VALUES (?,?)),
			    cell_width => 8}},

    genres             => {
	_worksheet => "genres",
	_field_order => [qw(ID work_id genre)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	genre           => {access => "rw",
			    data_type => "look_up",
			    look_up => "genres",
			    cell_width => 8}},

    instruments        => {
	_worksheet => "instruments",
	_field_order => [qw(work_id instrument role)],

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	instrument      => {access => "rw",
	 		    data_type => "look_up",
			    look_up => "instruments",
	 		    list_mutable => 1,
			    not_null => 1,
			    cell_width => 10},

	role            => {access => "rw",
			    data_type => "string",
			    cell_width => 8}},

    derived_from       => {
	_worksheet => "derived_from",
	_field_order => [qw(precusor_work derived_work derivation_relation)],

	precusor_work   => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    list_mutable => 0,
			    not_null => 1,
			    cell_width => 40},

	derived_work    => {access => "rw",
			    data_type => "look_up",
			    look_up => "parent_works",
			    list_mutable => 0,
			    not_null => 1,
			    cell_width => 40},
	
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
			    not_null => 1,
			    cell_width => 40},

	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => "manuscripts",
			    not_null => 1,
			    cell_width => 40},

	period_start    => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	work_type       => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_types",
			    cell_width => 10}},

    editions           => {
	_worksheet => "editions",
	_field_order => [qw(ID work_id date_made editor score_type work_extent notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	date_made       => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	editor          => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    cell_width => 30},

	score_type      => {access => "rw",
			    data_type => "look_up",
			    look_up => "score_types",
	 		    list_mutable => 1,
			    cell_width => 15},

	work_extent     => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    publications       => {
	_worksheet => "publications",
	_field_order => [qw(ID title publisher publication_place date_published serial_number notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	title           => {access => "rw",
			    data_type => "string",
			    not_null => 1,
			    cell_width => 20},

	publisher       => {access => "rw",
			    data_type => "string",
			    cell_width => 20},

	publication_place => {access => "rw",
			      data_type => "string",
			      cell_width => 15},

	date_published  => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	serial_number   => {access => "rw",
			    data_type => "string",
			    cell_width => 12},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    published_in       => {
	_worksheet => "published_in",
	_field_order => [qw(edition_id publication_id edition_extent publication_range)],

	edition_id      => {access => "rw",
			    data_type => "look_up",
			    look_up => "editions",
			    not_null => 1,
			    cell_width => 20},

	publication_id  => {access => "rw",
			    data_type => "look_up",
			    look_up => "publications",
			    not_null => 1,
			    cell_width => 20},

	edition_extent  => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	publication_range => {access => "rw",
			      data_type => "string",
			      cell_width => 8}},

    performances       => {
	_worksheet => "performances",
	_field_order => [qw(ID work_id date_performed venue_id performance_type notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	date_performed  => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	venue_id        => {access => "rw",
			    data_type => "integer",
			    cell_width => 8},

	performance_type => {access => "rw",
			     data_type => "look_up",
			     look_up => "performance_types",
			     cell_width => 15},

	notes           => {access => "rw",
			    data_type => "string"},
			    cell_width => 80},

    performed_in       => {
	_worksheet => "performed_in",
	_field_order => [qw(person_id performance_id role)],

	person_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    not_null => 1,
			    cell_width => 30},

	performance_id  => {access => "rw",
			    data_type => "look_up",
			    look_up => "performances",
			    not_null => 1,
			    cell_width => 20},

	role            => {access => "rw",
			    data_type => "string",
			    cell_width => 12}},

    letters            => {
	_worksheet => "letters",
	_field_order => [qw(ID letters_db_ID date_composed date_sent addressee signatory original_text english_text)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	letters_db_ID   => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	date_composed   => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	date_sent       => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	addressee       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    cell_width => 30},

	signatory       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    cell_width => 30},

	original_text   => {access => "rw",
			    data_type => "string",
			    cell_width => 60},

	english_text    => {access => "rw",
			    data_type => "string",
			    cell_width => 60}},

    letter_mentions    => {
	_worksheet => "letter_mentions",
	_field_order => [qw(ID letter_id letter_range mentioned_table mentioned_id mentioned_extent notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	letter_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => "letters",
			    not_null => 1,
			    cell_width => 20},

	letter_range    => {access => "rw",
			    data_type => "string",
			    cell_width => 12},

	mentioned_table => {access => "rw",
			    data_type => "look_up",
			    look_up => "mentionable_tables",
			    not_null => 1,
			    cell_width => 12},

	mentioned_id    => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8},

	mentioned_extent => {access => "rw",
			     data_type => "string",
			     cell_width => 12},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    manuscripts        => {
	_worksheet => "manuscripts",
	_field_order => [qw(ID title purpose physical_size medium extent missing date_made annotation_of location notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	title           => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 20},

	purpose         => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_types",
			    not_null => 1,
			    cell_width => 20},

	physical_size   => {access => "rw",
			    data_type => "string",
			    width => 32,
			    cell_width => 12},

	medium          => {access => "rw",
			    data_type => "string",
			    width => 32,
			    cell_width => 12},

	extent          => {access => "rw",
			    data_type => "integer",
			    cell_width => 12},

	missing         => {access => "rw",
			    data_type => "boolean",
			    not_null => 1,
			    default => 0,
			    cell_width => 8},

	date_made       => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)},

	annotation_of   => {access => "rw",
			    data_type => "look_up",
			    look_up => "editions",
			    cell_width => 20},

	location        => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 12},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    texts              => {
	_worksheet => "texts",
	_field_order => [qw(ID title author language original_content english_content)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	title           => {access => "rw",
			    data_type => "string",
			    width => 128,
			    not_null => 1,
			    cell_width => 20},

	author          => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    cell_width => 30},

	language        => {access => "rw",
			    data_type => "string",
			    width => 2,
			    cell_width => 8},

	original_content => {access => "rw",
			     data_type => "string",
			     cell_width => 60},

	english_content => {access => "rw",
			    data_type => "string",
			    cell_width => 60}},

    persons            => {
	_worksheet => "persons",
	_field_order => [qw(ID given_name family_name sex nationality)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	given_name      => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 20},

	family_name     => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 20},

	sex             => {access => "rw",
			    data_type => "look_up",
			    look_up => "sex",
			    cell_width => 8},

	nationality     => {access => "rw",
			    data_type => "string",
			    width => 2,
			    cell_width => 8}},

    dedicated_to       => {
	_worksheet => "dedicated_to",
	_field_order => [qw(ID work_id person_id manuscript_id edition_id dedication_text date_made)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	work_id         => {access => "rw",
			    data_type => "look_up",
			    look_up => "all_works",
			    not_null => 1,
			    cell_width => 40},

	person_id       => {access => "rw",
			    data_type => "look_up",
			    look_up => "persons",
			    not_null => 1,
			    cell_width => 30},

	manuscript_id   => {access => "rw",
			    data_type => "look_up",
			    look_up => "manuscripts",
			    cell_width => 30},

	edition_id      => {access => "rw",
			    data_type => "look_up",
			    look_up => "editions",
			    cell_width => 30},

	dedication_text => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	date_made       => {access => "rw",
			    data_type => "string",
			    value_parser => sub { },
			    insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    update => qq(UPDATE dates SET  WHERE ID=?)}},

    catalogues         => {
	_worksheet => "catalogues",
	_field_order => [qw(ID label title notes)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	label           => {access => "rw",
			    data_type => "string",
			    unique => 1,
			    width => 32,
			    cell_width => 20},

	title           => {access => "rw",
			    data_type => "string",
			    cell_width => 30},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    dates              => {
	_worksheet => "dates",
	_field_order => [qw(ID year year_accuracy month month_accuracy day day_accuracy end_year end_year_accuracy end_month end_month_accuracy end_day end_day_accuracy date_text source_table source_id)],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	year            => {access => "rw",
			    data_type => "integer",
			    minimum => 1000,
			    maximum => 9999,
			    cell_width => 8},

	year_accuracy   => {access => "rw",
			    data_type => "look_up",
			    look_up => "date_accuracy",
			    not_null => 1,
			    default => 'exactly',
			    cell_width => 8},

	month           => {access => "rw",
			    data_type => "integer",
			    minimum => 1,
			    maximum => 12,
			    cell_width => 8},

	month_accuracy  => {access => "rw",
			    data_type => "look_up",
			    look_up => "date_accuracy",
			    not_null => 1,
			    default => 'exactly',
			    cell_width => 8},

	day             => {access => "rw",
			    data_type => "integer",
			    minimum => 1,
			    maximum => 31,
			    cell_width => 8},

	day_accuracy    => {access => "rw",
			    data_type => "look_up",
			    look_up => "date_accuracy",
			    not_null => 1,
			    default => 'exactly',
			    cell_width => 8},

	end_year        => {access => "rw",
			    data_type => "integer",
			    minimum => 1000,
			    maximum => 9999,
			    cell_width => 8},

	end_year_accuracy => {access => "rw",
			      data_type => "look_up",
			      look_up => "date_accuracy",
			      not_null => 1,
			      default => 'exactly',
			      cell_width => 8},

	end_month       => {access => "rw",
			    data_type => "integer",
			    minimum => 1,
			    maximum => 12,
			    cell_width => 8},

	end_month_accuracy => {access => "rw",
			       data_type => "look_up",
			       look_up => "date_accuracy",
			       not_null => 1,
			       default => 'exactly',
			       cell_width => 8},

	end_day         => {access => "rw",
			    data_type => "integer",
			    minimum => 1,
			    maximum => 31,
			    cell_width => 8},

	end_day_accuracy  => {access => "rw",
			      data_type => "look_up",
			      look_up => "date_accuracy",
			      not_null => 1,
			      default => 'exactly',
			      cell_width => 8},

	date_text       => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 8},

	source_table    => {access => "rw",
			    data_type => "look_up",
			    look_up => "date_source_tables",
			    cell_width => 12},

	source_id       => {access => "rw",
			    data_type => "integer",
			    cell_width => 8}},

    media_items        => {},
    remote_media_items => {},
    representation_of  => {},
    resources          => {},
    resource_about     => {});

sub table_info {
    my $table_name = shift;
    $schema{$table_name};
}

sub get_record_stmt {
    my ($dbh, $table) = @_;

    my $sql = $schema{$table}->{_get};

    if (defined $sql) {
	return $dbh->prepare($sql);
    } else {
	die("No get record SQL for $table.\n");
    }
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
