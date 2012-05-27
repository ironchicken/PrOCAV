#
# ComposerCat
#
# This module provides prepared statements and other useful functions
# for working with the ComposerCat database.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::Schema;

use strict;

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(%look_ups @table_order %schema schema_prepare_statments $explanations);
}

use ComposerCat::Resources qw(dbpedia_uri);
use ComposerCat::Database qw(record_exists insert_record insert_resource);

#################################################################################################################
#### NAMED LOOK-UPS
#################################################################################################################

our %look_ups = (
    # The first values in this hash are subroutines which return a
    # list of hashes containing `value` and `display` fields. (They
    # are subroutines in order to be polymorphic with the other items
    # in the hash.)
    work_parent_relation => sub { [{value => "movement", display => "Movement"},
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
				   {value => "draft full score",              display => "Draft full score"},
				   {value => "autograph complete full score", display => "Autograph complete full score"},
				   {value => "annotated published score",     display => "Annotated published score"}]; },

    manuscript_parent_relation => sub { [{value => "fonds",      display => "Fonds"},
					 {value => "sub-fonds",  display => "Sub-fonds"},
					 {value => "series",     display => "Series"},
					 {value => "sub-series", display => "Sub-series"},
					 {value => "item",       display => "Item"}]; },

    archivable_entities  => sub { [{value => "manuscripts", display => "Manuscripts"},
				   {value => "letters",     display => "Letters"}]; },

    archival_access       => sub { [{value => "private", display => "Private"},
				    {value => "public",  display => "Public"}]; },

    archival_item_status  => sub { [{value => "original", display => "Original"},
				    {value => "copy",     display => "Copy"}]; },

    instrument_cardinality => sub { [{value => "solo",   display => "Solo"},
				     {value => "desk",   display => "Desk"},
				     {value => "chorus", display => "Chorus"}]; },

    performance_types    => sub { [{value => "concert", display => "Concert"},
				   {value => "broadcast", display => "Broadcast"},
				   {value => "recording", display => "Recording"},
				   {value => "staged", display => "Staged"},
				   {value => "semi-staged", display => "Semi-staged"},
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
				   {value => "dedicated_to", display => "Dedicated_to"},
				   {value => "commissioned_by", display => "Commissioned_by"}]; },

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

    no_author            => sub { [{value => "anonymous", display => "Anonymous"},
				   {value => "traditional", display => "Traditional"}]; },

    media_sources        => sub { [{value => "local", display => "Local media"}, {value => "remote", display => "Remote media"}]; },

    media_for            => sub { [{value => "works", display => "Works"},
				   {value => "editions", display => "Editions"},
				   {value => "publications", display => "Publications"},
				   {value => "performances", display => "Performances"},
				   {value => "letters", display => "Letters"},
				   {value => "manuscripts", display => "Manuscripts"},
				   {value => "texts", display => "Texts"},
				   {value => "media_items", display => "media_items"},
				   {value => "remote_media_items", display => "remote_media_items"}]; },

    media_content_types  => sub { [{value => "audio",    display => "Audio"},
				   {value => "notation", display => "Notation"},
				   {value => "text",     display => "Text"},
				   {value => "analysis", display => "Analysis"},
				   {value => "data",     display => "Data"}]; },

    media_relations      => sub { [{value => "digitisation", display => "Digitisation"},
				   {value => "transcription", display => "Transcription"},
				   {value => "features", display => "Features"}]; },

    resources_for        => sub { [{value => "works", display => "Works"},
				   {value => "titles", display => "Titles"},
				   {value => "genres", display => "Genres"},
				   {value => "instruments", display => "Instruments"},
				   {value => "composition", display => "Composition"},
				   {value => "editions", display => "Editions"},
				   {value => "publications", display => "Publications"},
				   {value => "performances", display => "Performances"},
				   {value => "letters", display => "Letters"},
				   {value => "letter_mentions", display => "Letter mentions"},
				   {value => "manuscripts", display => "Manuscripts"},
				   {value => "archives", display => "Archives"},
				   {value => "in_archive", display => "Item in archive"},
				   {value => "persons", display => "Persons"},
				   {value => "texts", display => "Texts"},
				   {value => "dedicated_to", display => "Dedicated_to"},
				   {value => "commissioned_by", display => "Commissioned_by"},
				   {value => "remote_media_items", display => "remote_media_items"}]; },

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
    parent_works         => sub { @_[0]->prepare(qq(SELECT works.ID AS value, CONCAT(uniform_title, IFNULL(CONCAT(" ", catalogues.label, number, IFNULL(suffix,"")),"")) AS display FROM works JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID JOIN catalogues ON catalogue_numbers.catalogue_id=catalogues.ID WHERE part_of IS NULL ORDER BY uniform_title)); },

    all_works            => sub { @_[0]->prepare(qq(SELECT works.ID AS value, CONCAT(uniform_title, IFNULL(CONCAT(" ", catalogues.label, number, IFNULL(suffix,"")),"")) AS display FROM works JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID JOIN catalogues ON catalogue_numbers.catalogue_id=catalogues.ID ORDER BY uniform_title)); },

    genres               => sub { @_[0]->prepare(qq(SELECT DISTINCT genre AS value, genre AS display FROM genres ORDER BY genre)); },

    instruments          => sub { @_[0]->prepare(qq(SELECT instrument AS value, instrument AS display FROM instruments ORDER BY instrument)); },

    manuscripts          => sub { @_[0]->prepare(qq(SELECT manuscripts.ID AS value, title AS display FROM manuscripts ORDER BY title)); },

    archives             => sub { @_[0]->prepare(qq(SELECT archives.ID AS value, IFNULL(abbreviation, title) AS display FROM archives ORDER BY display)); },

    editions             => sub { @_[0]->prepare(qq(SELECT editions.ID AS value, CONCAT(title, " (", publication_range, ")") AS display FROM editions JOIN published_in ON editions.ID=edition_id JOIN publications ON publications.ID=publication_id ORDER BY title)); },

    publications         => sub { @_[0]->prepare(qq(SELECT publications.ID AS value, title AS display FROM publications ORDER BY title)); },

    persons              => sub { @_[0]->prepare(qq(SELECT persons.ID AS value, CONCAT(family_name, ", ", given_name) AS display FROM persons ORDER BY family_name, given_name)); },

    score_types          => sub { @_[0]->prepare(qq(SELECT DISTINCT score_type AS value, score_type AS display FROM publications ORDER BY score_type)); },

    performances         => sub { @_[0]->prepare(qq(SELECT performances.ID AS value, CONCAT(works.uniform_title, " ", dates.day, "/", dates.month, "/", dates.year) AS display FROM performances JOIN works ON performances.work_id=works.ID JOIN dates ON performances.date_performed=dates.ID ORDER BY works.uniform_title, dates.year, dates.month, dates.day)); },

    letters              => sub { @_[0]->prepare(qq(SELECT letters.ID AS value, CONCAT("From: ", s.given_name, " ", s.family_name, "; To: ", a.given_name, " ", a.family_name, "; Date: ", c.year, "/", c.month, "/", c.day) AS display FROM letters LEFT JOIN persons AS s ON letters.signatory = s.ID LEFT JOIN persons AS a ON letters.addressee = a.ID LEFT JOIN dates AS c ON c.ID = letters.date_composed ORDER BY c.year, c.month, c.day)); },

    catalogues           => sub { @_[0]->prepare(qq(SELECT ID AS value, label AS display FROM catalogues ORDER BY label)); },

    media_items          => sub { @_[0]->prepare(qq(SELECT ID AS value, path AS display FROM media_items ORDER BY path)); },

    media_item_groups    => sub { @_[0]->prepare(qq(SELECT ID AS value, short_description AS display FROM media_groups ORDER BY short_description)); }

    );


#################################################################################################################
#### DATABASE SCHEMA
#################################################################################################################

our @table_order = qw(works musical_information catalogue_numbers titles composition genres work_status scored_for dedicated_to commissioned_by instruments manuscripts archives in_archive editions publications published_in performances venues performed_in letters letter_mentions texts persons catalogues dates media_items remote_media_items media_groups media_in_group representation_of resources resource_about);

our %schema = (
    works => {
	_worksheet => "works",

	_field_order         => [qw(ID uniform_title sub_title part_of parent_relation part_number part_position duration notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(uniform_title sub_title part_of parent_relation part_number part_position duration notes staff_notes)],
	_order_fields        => [qw(uniform_title)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	uniform_title   => {access => "rw",
			    data_type => "string",
			    not_null => 1,
			    cell_width => 20},

	sub_title       => {access => "rw",
			    data_type => "string",
			    cell_width => 20},

	# part_of         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "parent_works",
	# 		    list_mutable => 0,
	# 		    cell_width => 40},

	part_of         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "parent_works",
			    hint => "ID of parent work"},

	parent_relation => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_parent_relation",
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
			    cell_width => 80,
			    allow_markup => 1},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    musical_information => {
	_worksheet => "musical_information",

	_field_order         => [qw(work_id performance_direction key_signature tonic tonic_chromatic mode time_sig_beats time_sig_division staff_notes)],
	_unique_fields       => [qw(work_id)],
	_single_select_field => "work_id",
	_insert_fields       => [qw(work_id performance_direction key_signature tonic tonic_chromatic mode time_sig_beats time_sig_division staff_notes)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	performance_direction => {access => "rw",
				  data_type => "string",
				  width => 128,
				  cell_width => 15},

	key_signature   => {access => "rw",
			    data_type => "integer",
			    minimum => -7,
			    maximum => 7,
			    cell_width => 8},

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
			      cell_width => 8},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    titles => {
	_worksheet => "titles",

	_field_order         => [qw(ID work_id manuscript_id edition_id person_id title transliteration script language notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id manuscript_id edition_id person_id title transliteration script language notes staff_notes)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},
	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},
	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},
	# manuscript_id   => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "manuscripts",
	# 		    cell_width => 30},
	manuscript_id   => {access => "rw",
			    data_type => "integer",
			    foreign_key => "manuscripts",
	 		    look_up => "manuscripts",
			    hint => "ID of the manuscript where this title appears"},
	# edition_id      => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "editions",
	# 		    cell_width => 40},
	edition_id      => {access => "rw",
			    data_type => "integer",
			    foreign_key => "editions",
	 		    look_up => "editions",
			    hint => "ID of the edition where this title appears"},
	# person_id       => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    cell_width => 30},
	person_id       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person responsible for this title"},
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
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    catalogue_numbers  => {
	_worksheet => "catalogue_numbers",

	_field_order         => [qw(work_id catalogue_id number number_position suffix suffix_position staff_notes)],
	_unique_fields       => [qw(work_id)],
	_single_select_field => "work_id",
	_insert_fields       => [qw(work_id catalogue_id number number_position suffix suffix_position staff_notes)],
	_order_fields        => [qw(catalogue_id number_position suffix_position)],
	_default_order       => "ASC",

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	# catalogue_id    => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "catalogues",
	# 		    not_null => 1,
	# 		    cell_width => 20},

	catalogue_id    => {access => "rw",
			    data_type => "integer",
			    foreign_key => "catalogues",
	 		    look_up => "catalogues",
			    hint => "ID of the catalogue for this number"},

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
			    cell_width => 8},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},
	
    work_status        => {
	_worksheet => "work_status",

	_field_order         => [qw(work_id status)],
	_unique_fields       => [qw(work_id status)],
	_single_select_field => "work_id",
	_insert_fields       => [qw(work_id status)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},
	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	status          => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_status",
			    list_mutable => 0,
			    list_insert => qq(INSERT INTO work_status (work_id, status) VALUES (?,?)),
			    cell_width => 8}},

    genres             => {
	_worksheet => "genres",

	_field_order         => [qw(ID work_id genre)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id genre)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	# genre           => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "genres",
	# 		    cell_width => 8}},

	genre           => {access => "rw",
			    data_type => "string"}},

    scored_for         => {
	_worksheet => "scored_for",

	_field_order         => [qw(work_id instrument cardinality doubles_with role in_group notes staff_notes)],
	_unique_fields       => [qw(work_id instrument role)],
	_single_select_field => "work_id",
	_insert_fields       => [qw(work_id instrument cardinality doubles_with role in_group notes staff_notes)],
	_order_fields        => [qw(work_id instrument role)],
	_default_order       => "ASC",

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	# instrument      => {access => "rw",
	#  		    data_type => "look_up",
	# 		    look_up => "instruments",
	# 		    not_null => 1,
	# 		    cell_width => 10},

	instrument      => {access => "rw",
	 		    data_type => "string",
			    foreign_key => "instruments",
	 		    look_up => "instruments",
			    hint => "unique name of the instrument",
			    update_hook => sub { my ($dbh, $operation, $record) = @_;
						 ComposerCat::Database::insert_record("instruments",
							       {instrument => lc $record->{instrument}, description => undef},
							       {processing_hook => 1}) 
						     if (defined $record->{instrument} &&
							 ($record->{instrument} ne '') &&
							 (not ComposerCat::Database::record_exists("instruments",
											      {instrument => $record->{instrument}}))); }},

	cardinality     => {access => "rw",
			    data_type => "look_up",
			    look_up => "instrument_cardinality",
			    cell_width => 8},

	doubles_with    => {access => "rw",
	 		    data_type => "string",
			    foreign_key => "instruments",
	 		    look_up => "instruments",
			    hint => "unique name of the instrument"},

	role            => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	in_group        => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    derived_from       => {
	_worksheet => "derived_from",

	_field_order         => [qw(precursor_work derived_work derivation_relation staff_notes)],
	_unique_fields       => [qw(precursor_work derived_work derivation_relation)],
	_single_select_field => "precursor_work",
	_insert_fields       => [qw(precursor_work derived_work derivation_relation staff_notes)],
	_order_fields        => [qw(precursor_work)],
	_default_order       => "ASC",

	# precursor_work  => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "parent_works",
	# 		    list_mutable => 0,
	# 		    not_null => 1,
	# 		    cell_width => 40},

	precursor_work  => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "parent_works",
			    hint => "ID of the precursor work"},

	# derived_work    => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "parent_works",
	# 		    list_mutable => 0,
	# 		    not_null => 1,
	# 		    cell_width => 40},

	derived_work    => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "parent_works",
			    hint => "ID of the derived work"},
	
	derivation_relation => {access => "rw",
				data_type => "look_up",
				look_up => "derivation_relations",
				not_null => 1},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    composition        => {
	_worksheet => "composition",

	_field_order         => [qw(ID work_id manuscript_id period_start period_end work_type)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id manuscript_id period_start period_end work_type)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "parent_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "parent_works",
			    hint => "ID of the work worked on"},

	# manuscript_id   => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "manuscripts",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	manuscript_id   => {access => "rw",
			    data_type => "integer",
			    foreign_key => "manuscripts",
	 		    look_up => "manuscripts",
			    hint => "ID of the manscript worked on"},

	period_start    => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
	 		    look_up => "dates",
			    hint => "ID of the date this period started"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	period_end      => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
	 		    look_up => "dates",
			    hint => "ID of the date this period ended"},

	work_type       => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_types",
			    cell_width => 10}},

    instruments        => {
	_worksheet => "instruments",

	_field_order         => [qw(ID instrument sort_position description)],
	_unique_fields       => [qw(instrument)],
	_single_select_field => "instrument",
	_insert_fields       => [qw(instrument sort_position description)],
	_order_fields        => [qw(sort_position instrument)],
	_default_order       => "ASC",
	_auto_resource_insert => [sub { my ($dbh, $operation, $record) = @_;
					my $dbpedia_uri = dbpedia_uri($record->{instrument});
					ComposerCat::Database::insert_resource($operation, "instruments", $record,
							{uri => $dbpedia_uri, mime_type => 'text/html'})
					    if ($dbpedia_uri)}],

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	instrument      => {access => "rw",
			    data_type => "string",
			    not_null => 1,
			    unique => 1,
			    width => 255,
			    cell_width => 15},

	sort_position   => {access => "rw",
			    data_type => "integer",
			    cell_width => 8},

	description     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    editions           => {
	_worksheet => "editions",

	_field_order         => [qw(ID work_id date_made editor work_extent notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id date_made editor work_extent notes staff_notes)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	date_made       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
	 		    look_up => "dates",
			    hint => "ID of the date this edition was made"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	# editor          => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    cell_width => 30},

	editor          => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person who edited this edition"},

	work_extent     => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    publications       => {
	_worksheet => "publications",

	_field_order         => [qw(ID title publisher publication_place date_published serial_number score_type notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(title publisher publication_place date_published serial_number score_type notes staff_notes)],
	_order_fields        => [qw(title)],
	_default_order       => "ASC",

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
			    data_type => "integer",
			    foreign_key => "dates",
	 		    look_up => "dates",
			    hint => "ID of the date the publication was issued"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	serial_number   => {access => "rw",
			    data_type => "string",
			    cell_width => 12},

	score_type      => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    published_in       => {
	_worksheet => "published_in",

	_field_order         => [qw(edition_id publication_id edition_extent publication_range staff_notes)],
	_unique_fields       => [qw(edition_id publication_id)],
	_single_select_field => "edition_id",
	_insert_fields       => [qw(edition_id publication_id edition_extent publication_range staff_notes)],
	_order_fields        => [qw(publication_id)],
	_default_order       => "ASC",

	# edition_id      => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "editions",
	# 		    not_null => 1,
	# 		    cell_width => 20},

	edition_id      => {access => "rw",
			    data_type => "integer",
			    foreign_key => "editions",
	 		    look_up => "editions",
			    hint => "ID of the edition published"},

	# publication_id  => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "publications",
	# 		    not_null => 1,
	# 		    cell_width => 20},

	publication_id  => {access => "rw",
			    data_type => "integer",
			    foreign_key => "publications",
	 		    look_up => "publications",
			    hint => "ID of the publication in which the edition was published"},

	edition_extent  => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	publication_range => {access => "rw",
			      data_type => "string",
			      cell_width => 8},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    performances       => {
	_worksheet => "performances",

	_field_order         => [qw(ID work_id date_performed venue_id performance_type notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id date_performed venue_id performance_type notes staff_notes)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

	date_performed  => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
	 		    look_up => "dates",
			    hint => "ID of the date of the performance"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	venue_id        => {access => "rw",
			    data_type => "integer",
			    foreign_key => "venues",
	 		    look_up => "dates",
			    hint => "ID of the venue"},

	performance_type => {access => "rw",
			     data_type => "look_up",
			     look_up => "performance_types",
			     cell_width => 15},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    venues       => {
	_worksheet => "venues",

	_field_order         => [qw(ID name city country venue_type homepage notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(name city country venue_type homepage notes staff_notes)],
	_order_fields        => [qw(country city)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	name            => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 20},

	city            => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	country         => {access => "rw",
			    data_type => "string",
			    width => 2,
			    cell_width => 8},

	venue_type      => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 12},

	homepage        => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 20},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    performed_in       => {
	_worksheet => "performed_in",

	_field_order         => [qw(person_id performance_id role staff_notes)],
	_unique_fields       => [qw(person_id performance_id role)],
	_single_select_field => "person_id",
	_insert_fields       => [qw(person_id performance_id role staff_notes)],
	_order_fields        => [qw(performance_id)],
	_default_order       => "ASC",

	# person_id       => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    not_null => 1,
	# 		    cell_width => 30},

	person_id       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person who performed"},

	# performance_id  => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "performances",
	# 		    not_null => 1,
	# 		    cell_width => 20},

	performance_id  => {access => "rw",
			    data_type => "integer",
			    foreign_key => "performances",
	 		    look_up => "performances",
			    hint => "ID of the performance"},

	role            => {access => "rw",
			    data_type => "string",
			    cell_width => 12},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    letters            => {
	_worksheet => "letters",

	_field_order         => [qw(ID letters_db_ID date_composed date_sent addressee signatory original_text english_text staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(letters_db_ID date_composed date_sent addressee signatory original_text english_text staff_notes)],
	_order_fields        => [qw(ID)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	letters_db_ID   => {access => "rw",
			    data_type => "string",
			    cell_width => 8},

	date_composed   => {access => "rw",
			    data_type => "integer"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	date_sent       => {access => "rw",
			    data_type => "integer"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	# addressee       => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    cell_width => 30},

	addressee       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person the letter was addressed to"},

	# signatory       => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    cell_width => 30},

	signatory       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person the letter was signed by"},

	original_text   => {access => "rw",
			    data_type => "string",
			    cell_width => 60},

	english_text    => {access => "rw",
			    data_type => "string",
			    cell_width => 60},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    letter_mentions    => {
	_worksheet => "letter_mentions",

	_field_order         => [qw(ID letter_id letter_range mentioned_table mentioned_id mentioned_extent notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(letter_id letter_range mentioned_table mentioned_id mentioned_extent notes staff_notes)],
	_order_fields        => [qw(letter_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	# letter_id       => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "letters",
	# 		    not_null => 1,
	# 		    cell_width => 20},

	letter_id       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "letters",
	 		    look_up => "letters",
			    hint => "ID of the letter"},

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
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    manuscripts        => {
	_worksheet => "manuscripts",

	_field_order         => [qw(ID work_id title purpose part_of parent_relation physical_size medium extent missing date_made annotation_of notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(title work_id purpose part_of parent_relation physical_size medium extent missing date_made annotation_of notes staff_notes)],
	_order_fields        => [qw(title)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
			    look_up => "all_works",
			    hint => "ID of the work"},

	title           => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 20},

	purpose         => {access => "rw",
			    data_type => "look_up",
			    look_up => "work_types",
			    not_null => 1,
			    cell_width => 20},

	part_of         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "manuscripts",
	 		    look_up => "parent_manuscripts",
			    hint => "ID of parent manuscript"},

	parent_relation => {access => "rw",
			    data_type => "look_up",
			    look_up => "manuscript_parent_relation",
			    list_mutable => 0,
			    cell_width => 12},

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
			    data_type => "integer",
			    foreign_key => "dates",
			    look_up => "dates",
			    hint => "ID of the date this manuscript was made"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	# annotation_of   => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "editions",
	# 		    cell_width => 20},

	annotation_of   => {access => "rw",
			    data_type => "integer",
			    foreign_key => "editions",
	 		    look_up => "editions",
			    hint => "ID of an edition of which this manuscript is an annotation"},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    archives           => {
	_worksheet => "archives",

	_field_order         => [qw(ID title abbreviation date_established date_disbanded location city country uri telephone email latitude longitude notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(ID title abbreviation date_established date_disbanded location city country uri telephone email latitude longitude notes staff_notes)],
	_order_fields        => [qw(abbreviation)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	title           => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 20},

	abbreviation    => {access => "rw",
			    data_type => "string",
			    width => 16,
			    cell_width => 8},

	abbreviation    => {access => "rw",
			    data_type => "string",
			    width => 16,
			    cell_width => 8},

	date_established => {access => "rw",
			     data_type => "integer",
			     foreign_key => "dates",
			     look_up => "dates",
			     hint => "ID of the date this archive was established"},

	date_disbanded  => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
			    look_up => "dates",
			    hint => "ID of the date this archive was disbanded"},

	location        => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	city            => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 12},

	country         => {access => "rw",
			    data_type => "string",
			    width => 2,
			    cell_width => 8},

	uri             => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	telephone       => {access => "rw",
			    data_type => "string",
			    width => 32,
			    cell_width => 15},

	email           => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},
	latitude        => {access => "rw",
			    data_type => "decimal",
			    cell_width => 8},

	longitude       => {access => "rw",
			    data_type => "decimal",
			    cell_width => 8},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    in_archive         => {
	_worksheet => "in_archive",

	_field_order         => [qw(entity_type entity_id archive_id archival_ref_str archival_ref_num date_acquired date_released access item_status copy_type copyright notes staff_notes)],
	_unique_fields       => [qw(entity_type entity_id archive_id)],
	_single_select_field => "entity_id",
	_insert_fields       => [qw(entity_type entity_id archive_id archival_ref_str archival_ref_num date_acquired date_released access item_status copy_type copyright notes staff_notes)],
	_order_fields        => [qw(archive_id archival_ref_num archival_ref_str entity_type entity_id)],
	_default_order       => "ASC",

	entity_type     => {access => "rw",
			    data_type => "look_up",
			    look_up => "archivable_entities",
			    not_null => 1,
			    cell_width => 8},

	entity_id       => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8,
			    hint => "ID of the item"},

	archive_id      => {access => "rw",
			    data_type => "integer",
			    foreign_key => "archives",
			    look_up => "archives",
			    not_null => 1,
			    cell_width => 12,
			    hint => "ID of the archive in which the item is housed"},

	archival_ref_str => {access => "rw",
			     data_type => "string",
			     cell_width => 12},

	archival_ref_num => {access => "rw",
			     data_type => "integer",
			     cell_width => 12},
			    
	date_acquired   => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
			    look_up => "dates",
			    hint => "ID of the date this item was acquired by the archive"},

	date_released   => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
			    look_up => "dates",
			    hint => "ID of the date this item was released from the archive"},

	access          => {access => "rw",
			    data_type => "look_up",
			    look_up => "archival_access",
			    cell_width => 8},

	item_status     => {access => "rw",
			    data_type => "look_up",
			    look_up => "archival_item_status",
			    not_null => 1,
			    default => 'original',
			    cell_width => 8},

	copy_type       => {access => "rw",
			    data_type => "string",
			    width => 32,
			    cell_width => 12},

	copyright       => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    texts              => {
	_worksheet => "texts",

	_field_order         => [qw(ID title author no_author text_type original language source citation original_content english_content notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(title author no_author text_type original language source citation original_content english_content notes staff_notes)],
	_order_fields        => [qw(title)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	title           => {access => "rw",
			    data_type => "string",
			    width => 128,
			    not_null => 1,
			    cell_width => 20},

	# author          => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    cell_width => 30},

	author          => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person who wrote this text"},

	no_author       => {access => "rw",
			    data_type => "look_up",
			    look_up => "no_author",
			    cell_width => 8},

	text_type       => {access => "rw",
			    data_type => "string",
			    width => 64,
			    cell_width => 12},

	original        => {access => "rw",
			    data_type => "boolean",
			    not_null => 1,
			    default => 0,
			    cell_width => 8},

	language        => {access => "rw",
			    data_type => "string",
			    width => 2,
			    cell_width => 8},

	source          => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 12},

	citation        => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 12},

	original_content => {access => "rw",
			     data_type => "string",
			     cell_width => 60},

	english_content => {access => "rw",
			    data_type => "string",
			    cell_width => 60},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    persons            => {
	_worksheet => "persons",

	_field_order         => [qw(ID given_name family_name sex nationality notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(given_name family_name sex nationality notes staff_notes)],
	_order_fields        => [qw(family_name given_name)],
	_default_order       => "ASC",

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
			    cell_width => 8},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    dedicated_to       => {
	_worksheet => "dedicated_to",

	_field_order         => [qw(ID work_id person_id manuscript_id edition_id dedication_text date_made staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id person_id manuscript_id edition_id dedication_text date_made staff_notes)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	# work_id         => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "all_works",
	# 		    not_null => 1,
	# 		    cell_width => 40},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
	 		    look_up => "all_works",
			    hint => "ID of the work"},

 	# person_id       => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "persons",
	# 		    not_null => 1,
	# 		    cell_width => 30},

	person_id       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
	 		    look_up => "persons",
			    hint => "ID of the person to whom the dedication was made"},

	# manuscript_id   => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "manuscripts",
	# 		    cell_width => 30},

	manuscript_id   => {access => "rw",
			    data_type => "integer",
			    foreign_key => "manuscripts",
	 		    look_up => "manuscripts",
			    hint => "ID of the manuscript on which the dedication is found"},

	# edition_id      => {access => "rw",
	# 		    data_type => "look_up",
	# 		    look_up => "editions",
	# 		    cell_width => 30},

	edition_id      => {access => "rw",
			    data_type => "integer",
			    foreign_key => "editions",
	 		    look_up => "editions",
			    hint => "ID of the edition in which the dedication is found"},

	dedication_text => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	date_made       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
			    look_up => "dates",
			    hint => "ID of the date this dedication was made"},
			    #value_parser => sub { },
			    #insert => qq(INSERT INTO dates (`year`, `month`, `day`, year_accuracy, month_accuracy, day_accuracy, end_year, end_month, end_day, end_year_accuracy, end_month_accuracy, end_day_accuracy) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)),
			    #update => qq(UPDATE dates SET  WHERE ID=?)},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    commissioned_by     => {
	_worksheet => "commissioned_by",

	_field_order         => [qw(ID work_id person_id commission_text date_made notes staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(work_id person_id commission_text date_made notes staff_notes)],
	_order_fields        => [qw(work_id)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	work_id         => {access => "rw",
			    data_type => "integer",
			    foreign_key => "works",
			    look_up => "parent_works",
			    hint => "ID of the work"},

	person_id       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "persons",
			    look_up => "dates",
			    hint => "ID of the person who made the commission"},

	commission_text => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 15},

	date_made       => {access => "rw",
			    data_type => "integer",
			    foreign_key => "dates",
			    look_up => "dates",
			    hint => "ID of the date the work was commissioned"},

	notes           => {access => "rw",
			    data_type => "string",
			    cell_width => 80},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    catalogues         => {
	_worksheet => "catalogues",

	_field_order         => [qw(ID label title notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(label title notes)],
	_order_fields        => [qw(label)],
	_default_order       => "ASC",

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

	_field_order         => [qw(ID year year_accuracy month month_accuracy day day_accuracy end_year end_year_accuracy end_month end_month_accuracy end_day end_day_accuracy date_text source_table source_id staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(year year_accuracy month month_accuracy day day_accuracy end_year end_year_accuracy end_month end_month_accuracy end_day end_day_accuracy date_text source_table source_id staff_notes)],
	_order_fields        => [qw(year month day)],
	_default_order       => "DESC",

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
			    cell_width => 8},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    media_items        => {
	_worksheet => "media_items",

	_field_order         => [qw(ID mime_type path content_type extent resolution date_made date_acquired copyright public staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(mime_type path content_type extent resolution date_made date_acquired copyright public staff_notes)],
	_order_fields        => [qw(path)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	mime_type       => {access => "rw",
			    data_type => "string",
			    width => 32,
			    not_null => 1,
			    cell_width => 15},

	path            => {access => "rw",
			    data_type => "string",
			    unique => 1,
			    not_null => 1,
			    width => 255,
			    cell_width => 30},

	content_type    => {access => "rw",
			    data_type => "look_up",
			    look_up => "media_content_types",
			    not_null => 1,
			    cell_width => 12},

	extent          => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	resolution      => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	date_made       => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	date_acquired   => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	copyright       => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 20},

	public          => {access => "rw",
			    data_type => "boolean",
			    not_null => 1,
			    default => 1,
			    cell_width => 8},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    remote_media_items  => {
	_worksheet => "remote_media_items",

	_field_order         => [qw(ID mime_type uri content_type extent resolution date_made date_linked copyright public staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(mime_type uri content_type extent resolution date_made date_linked copyright public staff_notes)],
	_order_fields        => [qw(uri)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	mime_type       => {access => "rw",
			    data_type => "string",
			    width => 32,
			    not_null => 1,
			    cell_width => 15},

	uri             => {access => "rw",
			    data_type => "string",
			    unique => 1,
			    not_null => 1,
			    width => 255,
			    cell_width => 30},

	content_type    => {access => "rw",
			    data_type => "look_up",
			    look_up => "media_content_types",
			    not_null => 1,
			    cell_width => 12},

	extent          => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	resolution      => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	date_made       => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	date_linked     => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	copyright       => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 20},

	public          => {access => "rw",
			    data_type => "boolean",
			    not_null => 1,
			    default => 1,
			    cell_width => 8},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    media_groups       => {
	_worksheet => "media_groups",

	_field_order         => [qw(ID short_description staff_notes)],
	_unique_fields       => [qw(ID)],
	_single_select_field => "ID",
	_insert_fields       => [qw(short_description staff_notes)],
	_order_fields        => [qw(ID)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	short_description => {access => "rw",
			      data_type => "string",
			      width => 64,
			      cell_width => 30},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    media_in_group     => {
	_worksheet => "media_items",

	_field_order         => [qw(media_id group_id position)],
	_unique_fields       => [qw(media_id group_id position)],
	_single_select_field => "media_id",
	_insert_fields       => [qw(media_id group_id position)],
	_order_fields        => [qw(group_id position)],
	_default_order       => "ASC",

	# media_id         => {access => "rw",
	# 		     data_type => "look_up",
	# 		     look_up => "media_items",
	# 		     not_null => 1,
	# 		     cell_width => 40},

	media_id         => {access => "rw",
			     data_type => "integer",
			     foreign_key => "media_items",
	 		     look_up => "media_items",
			     hint => "ID of the media item"},

	# group_id         => {access => "rw",
	# 		     data_type => "look_up",
	# 		     look_up => "media_item_groups",
	# 		     not_null => 1,
	# 		     cell_width => 40},

	group_id         => {access => "rw",
			     data_type => "integer",
			     foreign_key => "media_item_groups",
	 		     look_up => "media_item_groups",
			     hint => "ID of the group"},

	position         => {access => "rw",
			     data_type => "integer",
			     cell_width => 8}},

    representation_of  => {
	_worksheet => "representation_of",

	_field_order         => [qw(source media_id related_table related_id relation)],
	_unique_fields       => [qw(source media_id related_table related_id)],
	_single_select_field => "media_id",
	_insert_fields       => [qw(source media_id related_table related_id relation)],
	_order_fields        => [qw(related_table related_id media_id)],
	_default_order       => "ASC",

	source          => {access => "rw",
			    data_type => "look_up",
			    look_up => "media_sources",
			    not_null => 1,
			    cell_width => 10},

	media_id        => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8},

	related_table   => {access => "rw",
			    data_type => "look_up",
			    look_up => "media_for",
			    not_null => 1,
			    cell_width => 10},

	related_id      => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8},

	relation        => {access => "rw",
			    data_type => "look_up",
			    look_up => "media_relations",
			    cell_width => 12}},

    resources          => {
	_worksheet => "resources",

	_field_order         => [qw(ID uri title mime_type date_made date_linked staff_notes)],
	_unique_fields       => [qw(uri)],
	_single_select_field => "ID",
	_insert_fields       => [qw(uri title mime_type date_made date_linked staff_notes)],
	_order_fields        => [qw(uri)],
	_default_order       => "ASC",

	ID              => {access => "ro",
			    primary_key => 1,
			    cell_width => 8},

	uri             => {access => "rw",
			    data_type => "string",
			    unique => 1,
			    not_null => 1,
			    width => 255,
			    cell_width => 30},

	title           => {access => "rw",
			    data_type => "string",
			    width => 255,
			    cell_width => 30},

	mime_type       => {access => "rw",
			    data_type => "string",
			    width => 32,
			    not_null => 1,
			    cell_width => 15},

	date_made       => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	date_linked     => {access => "rw",
			    data_type => "string",
			    width => 128,
			    cell_width => 15},

	staff_notes     => {access => "rw",
			    data_type => "string",
			    cell_width => 80}},

    resource_about     => {
	_worksheet => "resource_about",

	_field_order         => [qw(resource_id related_table related_id relation)],
	_unique_fields       => [qw(resource_id related_table related_id)],
	_single_select_field => "resource_id",
	_insert_fields       => [qw(resource_id related_table related_id relation)],
	_order_fields        => [qw(related_table related_id)],
	_default_order       => "ASC",

	resource_id     => {access => "rw",
			    data_type => "integer",
			    foreign_key => "resources",
			    look_up => "resources",
			    hint => "ID of the resource",
			    not_null => 1,
			    cell_width => 8},

	related_table   => {access => "rw",
			    data_type => "look_up",
			    look_up => "resources_for",
			    not_null => 1,
			    cell_width => 10},

	related_id      => {access => "rw",
			    data_type => "integer",
			    not_null => 1,
			    cell_width => 8},

	relation        => {access => "rw",
			    data_type => "string",
			    cell_width => 12}});

sub schema_prepare_statments {
    my $dbh = shift;

    sub date_selector {
	my $name = shift;

	"$name.year AS $name\_year, $name.year_accuracy AS $name\_year_accuracy, " .
	    "$name.month AS $name\_month, $name.month_accuracy AS $name\_month_accuracy, " . 
	    "$name.day AS $name\_day, $name.day_accuracy AS $name\_day_accuracy, " . 
	    "$name.end_year AS $name\_end_year, $name.end_year_accuracy AS $name\_end_year_accuracy, " . 
	    "$name.end_month AS $name\_end_month, $name.end_month_accuracy AS $name\_end_month_accuracy, " . 
	    "$name.end_day AS $name\_end_day, $name.end_day_accuracy AS $name\_end_day_accuracy, " . 
	    "$name.date_text AS $name\_date_text ";
    }

    ######################################################################################################
    ### WORKS TABLE STATEMENTS
    ######################################################################################################

    # works._full retrieves a single WORKS with its MUSICAL_INFORMATION
    $schema{works}->{_full} = $dbh->prepare_cached(q|SELECT works.ID, works.uniform_title, works.sub_title,
    works.part_of, works.parent_relation, works.duration, works.notes,
    musical_information.performance_direction, musical_information.tonic,
    musical_information.tonic_chromatic, musical_information.mode,
    musical_information.time_sig_beats, musical_information.time_sig_division
    FROM works
    LEFT JOIN musical_information ON musical_information.work_id = works.ID
    WHERE works.ID=?|);

    # works._sub_works retrieves all the records from the WORKS table
    # which stand in a part_of relation with the given WORKS record
    $schema{works}->{_sub_works} = $dbh->prepare_cached(q|SELECT works.ID, sub_works.ID, sub_works.uniform_title, sub_works.sub_title, sub_works.parent_relation,
    sub_works.duration, sub_works.notes, musical_information.performance_direction,
    musical_information.tonic, musical_information.tonic_chromatic,
    musical_information.mode, musical_information.time_sig_beats,
    musical_information.time_sig_division
    FROM works
    JOIN works AS sub_works ON sub_works.part_of = works.ID
    LEFT JOIN musical_information ON musical_information.work_id = sub_works.ID
    WHERE works.ID=?
    ORDER BY sub_works.part_position|);

    # works._parent
    $schema{works}->{_parent} = $dbh->prepare_cached(q|SELECT parent.ID, parent.uniform_title, parent.sub_title,
    parent.part_of, parent.parent_relation, parent.duration, parent.notes,
    musical_information.performance_direction, musical_information.tonic,
    musical_information.tonic_chromatic, musical_information.mode,
    musical_information.time_sig_beats, musical_information.time_sig_division
    FROM works AS parent
    JOIN works ON parent.ID=works.part_of
    LEFT JOIN musical_information ON musical_information.work_id = parent.ID
    WHERE works.ID=?|);

    # works._statuses retrieves all the WORK_STATUSs for a given
    # WORKS.ID
    $schema{works}->{_statuses} = $dbh->prepare_cached(q|SELECT work_id, status FROM work_status WHERE work_id=?|);

    # works._titles retrieves all the TITLEs for a given WORKS.ID
    $schema{works}->{_titles} = $dbh->prepare_cached(q|SELECT titles.ID, titles.title, titles.transliteration,
    titles.language, titles.script, manuscripts.title AS manuscript_title, persons.given_name, persons.family_name
    FROM titles
    LEFT JOIN manuscripts ON manuscripts.ID = titles.manuscript_id
    LEFT JOIN editions ON editions.ID = titles.edition_id
    LEFT JOIN persons ON editions.ID = titles.person_id
    WHERE titles.work_id=?
    ORDER BY titles.title|);

    # works._catalogue_numbers
    $schema{works}->{_catalogue_numbers} = $dbh->prepare_cached(q|SELECT catalogues.label, catalogue_numbers.number,
    catalogue_numbers.number_position, catalogue_numbers.suffix, catalogue_numbers.suffix_position
    FROM catalogue_numbers
    JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE catalogue_numbers.work_id=?
    ORDER BY catalogue_numbers.number_position, catalogue_numbers.suffix_position|);

    # works._genres
    $schema{works}->{_genres} = $dbh->prepare_cached(q|SELECT genres.ID, genres.genre
    FROM genres
    WHERE genres.work_id=?
    ORDER BY genres.genre|);

    # works._scored_for
    $schema{works}->{_scored_for} = $dbh->prepare_cached(q|SELECT scored_for.instrument, scored_for.cardinality,
    scored_for.doubles_with, scored_for.role, scored_for.in_group, scored_for.notes
    FROM scored_for
    JOIN instruments ON scored_for.instrument = instruments.instrument
    WHERE scored_for.work_id=?
    ORDER BY scored_for.in_group, instruments.sort_position|);

    # works._derived_from
    $schema{works}->{_derived_from} = $dbh->prepare_cached(q|SELECT derived_work, derivation_relation, notes
    FROM derived_from
    WHERE precursor_work=?
    ORDER BY derivation_relation, derived_work|);

    # works._derivations
    $schema{works}->{_derivations} = $dbh->prepare_cached(q|SELECT precursor_work, derivation_relation, notes
    FROM derived_from
    WHERE derived_work=?
    ORDER BY derivation_relation, precursor_work|);

    # works._composition
    $schema{works}->{_composition} = $dbh->prepare_cached(q|SELECT composition.ID, manuscripts.title AS manuscript_title, | . date_selector("start") . ', ' . date_selector("end") . q|, composition.work_type
    FROM composition
    LEFT JOIN dates AS start ON composition.period_start = start.ID
    LEFT JOIN dates AS end ON composition.period_end = end.ID
    LEFT JOIN manuscripts ON composition.manuscript_id = manuscripts.ID
    WHERE composition.work_id=?
    ORDER BY end.year, end.month, end.day, composition.work_type|);

    # works._editions
    $schema{works}->{_editions} = $dbh->prepare_cached(q|SELECT editions.ID, | . date_selector("made") . q|, editor.given_name AS editor_given_name,
    editor.family_name AS editor_family_name, editions.work_extent, editions.notes
    FROM editions
    LEFT JOIN dates AS made ON editions.date_made = made.ID
    LEFT JOIN persons AS editor ON editions.editor = editor.ID
    WHERE editions.work_id=?
    ORDER BY made.year, made.month, made.day|);

    # works._publications
    $schema{works}->{_publications} = $dbh->prepare_cached(q|SELECT publications.ID, publications.title, publications.publisher,
    publications.publication_place, | . date_selector('pub_date') . q|, publications.serial_number, publications.score_type,
    publications.notes, published_in.edition_extent, published_in.publication_range
    FROM publications
    JOIN published_in ON published_in.publication_id = publications.ID
    JOIN editions ON published_in.edition_id = editions.ID
    LEFT JOIN dates AS pub_date ON publications.date_published = pub_date.ID
    WHERE editions.work_id=?
    ORDER BY pub_date.year, pub_date.month, pub_date.day|);

    # works._performanes
    $schema{works}->{_performances} = $dbh->prepare_cached(q|SELECT performances.ID, | . date_selector('performed') . q|, venues.name AS venue, venues.city,
    venues.country, venues.venue_type, performances.performance_type, performances.notes
    FROM performances
    LEFT JOIN dates AS performed ON performances.date_performed = performed.ID
    LEFT JOIN venues ON performances.venue_id = venues.ID
    WHERE performances.work_id=?
    ORDER BY performed.year, performed.month, performed.day|);

    # works._letters
    $schema{works}->{_letters} = $dbh->prepare_cached(q|SELECT letters.ID, | . date_selector('composed') . ', ' . date_selector('sent') . q|,
    addressee.given_name AS addressee_given_name, addressee.family_name AS addressee_family_name, signatory.given_name AS signatory_given_name,
    addressee.family_name AS signatory_family_name, letters.original_text, letters.english_text, letter_mentions.letter_ragne,
    letter_mentions.mentioned_extent AS work_extent, letter_mentions.notes
    FROM letters
    JOIN letter_mentions ON letter_mentions.letter_id = letters.ID
    LEFT JOIN dates AS composed ON letters.date_composed = composed.ID
    LEFT JOIN dates AS sent ON letters.date_sent = sent.ID
    LEFT JOIN persons AS addressee ON letters.addressee = addressee.ID
    LEFT JOIN persons AS signatory ON letters.signatory = signatory.ID
    WHERE letter_mentions.mentioned_table = "works" AND letter_mentions.mentioned_id=?
    ORDER BY composed.year, composed.month, composed.day|);

    #works._manuscripts
    $schema{works}->{_manuscripts} = $dbh->prepare_cached(q|SELECT manuscripts.ID, manuscripts.title, manuscripts.purpose, manuscripts.physical_size,
    manuscripts.medium, manuscripts.extent, manuscripts.missing, | . date_selector('made') . q|, manuscripts.annotation_of,
    manuscripts.notes, archives.ID AS archive_id, archives.abbreviation AS archive_abbr, archives.title AS archive
    FROM manuscripts
    LEFT JOIN dates AS made ON manuscripts.date_made = made.ID
    -- LEFT JOIN editions AS annotated_edition ON manuscripts.annotation_of = annotated_edition.ID
    LEFT JOIN in_archive ON in_archive.entity_id = manuscripts.ID
    LEFT JOIN archives ON in_archive.archive_id = archives.ID
    WHERE manuscripts.work_id=? AND (in_archive.entity_type = "manuscripts" OR in_archive.entity_type IS NULL)
    ORDER BY made.year, made.month, made.day, manuscripts.purpose|);

    # works._texts
    $schema{works}->{_texts} = $dbh->prepare_cached(q|SELECT texts.ID, texts.title, author.given_name AS author_given_name,
    author.family_name AS author_family_name, texts.no_author, texts.text_type, texts.original, texts.language, texts.source,
    texts.citation, texts.original_content, texts.english_content, texts.notes
    FROM texts
    JOIN work_sets_text ON work_sets_text.text_id = texts.ID
    LEFT JOIN persons AS author ON texts.author = author.ID
    WHERE work_sets_text.work_id=?|);

    # works._dedicated_to
    $schema{works}->{_dedicated_to} = $dbh->prepare_cached(q|SELECT dedicatee.ID, dedicatee.given_name AS dedicatee_given_name,
    dedicatee.family_name AS dedicatee_family_name, manuscripts.title AS manuscript_title, edition_date.year AS edition,
    dedicated_to.dedication_text, | . date_selector('made') . q|
    FROM dedicated_to
    JOIN persons AS dedicatee ON dedicated_to.person_id = dedicatee.ID
    LEFT JOIN manuscripts ON dedicated_to.manuscript_id = manuscripts.ID
    LEFT JOIN editions ON dedicated_to.edition_id = editions.ID
    LEFT JOIN dates AS edition_date ON editions.date_made = edition_date.ID
    LEFT JOIN dates AS made ON dedicated_to.date_made = made.ID
    WHERE dedicated_to.work_id=?
    ORDER BY made.year, made.month, made.day|);

    # works._commissioned_by
    $schema{works}->{_commissioned_by} = $dbh->prepare_cached(q|SELECT commissioner.ID, commissioner.given_name AS commissioner_given_name,
    commissioner.family_name AS commissioner_family_name, commissioned_by.commission_text, | . date_selector('made') . q|
    FROM commissioned_by
    JOIN persons AS commissioner ON commissioned_by.person_id = commissioner.ID
    LEFT JOIN dates AS made ON commissioned_by.date_made = made.ID
    WHERE commissioned_by.work_id=?
    ORDER BY made.year, made.month, made.day|);

    # works._local_media_items
    $schema{works}->{_local_media_items} = $dbh->prepare_cached(q|SELECT media_items.ID, media_items.mime_type, media_items.path,
    media_items.content_type, media_items.extent, media_items.resolution, media_items.date_made, media_items.date_acquired,
    media_items.copyright, media_items.public, representation_of.relation
    FROM media_items
    JOIN representation_of ON representation_of.media_id = media_items.ID
    WHERE representation_of.source = "local" AND representation_of.related_table = "works" AND related_id=?|);

    # works._remote_media_items
    $schema{works}->{_remote_media_items} = $dbh->prepare_cached(q|SELECT remote_media_items.ID, remote_media_items.mime_type,
    remote_media_items.uri, remote_media_items.content_type, remote_media_items.extent, remote_media_items.resolution,
    remote_media_items.date_made, remote_media_items.date_linked, remote_media_items.copyright, remote_media_items.public,
    representation_of.relation
    FROM remote_media_items
    JOIN representation_of ON representation_of.media_id = remote_media_items.ID
    WHERE representation_of.source = "remote" AND representation_of.related_table = "works" AND representation_of.related_id=?|);

    # works._local_media_groups
    $schema{works}->{_local_media_groups} = $dbh->prepare(q|SELECT media_items.ID, media_items.mime_type, media_items.path,
    media_items.extent, media_items.resolution, media_items.date_made, media_items.date_acquired, media_items.copyright,
    media_items.public, representation_of.relation, media_in_group.position, media_groups.short_description
    FROM media_in_group
    JOIN media_items ON media_in_group.media_id = media_items.ID
    JOIN media_groups ON media_in_group.group_id = media_groups.ID
    JOIN representation_of ON representation_of.media_id = media_in_group.group_id
    WHERE media_in_group.source = "local" AND representation_of.source = "group"
      AND representation_of.related_table = "works" AND representation_of.related_id=?
    ORDER BY media_groups.ID, media_in_group.position|);

    # works._remote_media_groups
    $schema{works}->{_remote_media_groups} = $dbh->prepare(q|SELECT remote_media_items.ID, remote_media_items.mime_type, remote_media_items.uri,
    remote_media_items.extent, remote_media_items.resolution, remote_media_items.date_made, remote_media_items.date_linked, remote_media_items.copyright,
    remote_media_items.public, representation_of.relation, media_in_group.position, media_groups.short_description
    FROM media_in_group
    JOIN remote_media_items ON media_in_group.media_id = remote_media_items.ID
    JOIN media_groups ON media_in_group.group_id = media_groups.ID
    JOIN representation_of ON representation_of.media_id = media_in_group.group_id
    WHERE media_in_group.source = "remote" AND representation_of.source = "group"
      AND representation_of.related_table = "works" AND representation_of.related_id=?
    ORDER BY media_groups.ID, media_in_group.position|);

    # works._resources
    $schema{works}->{_resources} = $dbh->prepare(q|SELECT resources.uri, resources.title, resources.mime_type, resources.date_made,
    resources.date_linked, resource_about.relation
    FROM resources
    JOIN resource_about ON resource_about.resource_id = resources.ID
    WHERE resource_about.related_table = "works" AND resource_about.related_id=?|);

    # works._complete defines the queries necessary to retrieve a work
    # and all its associated records
    $schema{works}->{_complete} = {details            => ['ONE', '_full'],
				   sub_work           => ['MANY', '_sub_works'],
				   parent             => ['ONE', '_parent'],
				   status             => ['MANY', '_statuses'],
				   title              => ['MANY', '_titles'],
				   catalogue_number   => ['MANY', '_catalogue_numbers'],
				   genre              => ['MANY', '_genres'],
				   scored_for         => ['MANY', '_scored_for'],
				   derived_from       => ['MANY', '_derived_from'],
				   derivation         => ['MANY', '_derivations'],
				   composition        => ['MANY', '_composition'],
				   edition            => ['MANY', '_editions'],
				   publication        => ['MANY', '_publications'],
				   performance        => ['MANY', '_performances'],
				   letter             => ['MANY', '_letters'],
				   manuscript         => ['MANY', '_manuscripts'],
				   text_set           => ['MANY', '_texts'],
				   dedicated_to       => ['MANY', '_dedicated_to'],
				   commissioned_by    => ['MANY', '_commissioned_by'],
				   local_media_item   => ['MANY', '_local_media_items'],
				   remote_media_item  => ['MANY', '_remote_media_items'],
				   local_media_group  => ['MANY', '_local_media_groups'],
				   remote_media_group => ['MANY', '_remote_media_groups'],
				   resource           => ['MANY', '_resources']};

    # works._list_by_scored_for
    $schema{works}->{_list_by_scored_for} = $dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    JOIN scored_for ON works.ID=scored_for.work_id
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE scored_for.instrument LIKE ? AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    GROUP BY works.ID
    ORDER BY end.year ASC|);

    # works._list_by_scored_for_any
    $schema{works}->{_list_by_scored_for_any} = $dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    JOIN scored_for ON works.ID=scored_for.work_id
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE scored_for.instrument RLIKE ? AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    GROUP BY works.ID
    ORDER BY end.year ASC|);

    # works._list_by_scored_for_all
    $schema{works}->{_list_by_scored_for_all} = sub {
	$dbh->prepare(sprintf(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE (%s) AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    ORDER BY end.year ASC|, join(' AND ', (('UPPER(?) IN (SELECT UPPER(instrument) FROM scored_for WHERE works.ID=scored_for.work_id)') x scalar @_))));
    };

    # works._list_by_scored_for_not_any
    $schema{works}->{_list_by_scored_for_not_any} = sub {
	$dbh->prepare(sprintf(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE (%s) AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    ORDER BY end.year ASC|, join(' OR ', (('UPPER(?) NOT IN (SELECT UPPER(instrument) FROM scored_for WHERE works.ID=scored_for.work_id)') x scalar @_))));
    };

    # works._list_by_scored_for_not_all
    $schema{works}->{_list_by_scored_for_not_all} = sub {
	$dbh->prepare(sprintf(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE (%s) AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    ORDER BY end.year ASC|, join(' AND ', (('UPPER(?) NOT IN (SELECT UPPER(instrument) FROM scored_for WHERE works.ID=scored_for.work_id)') x scalar @_))));
    };

    # works._list_by_genre
    $schema{works}->{_list_by_genre} = $dbh->prepare(q|SELECT works.* FROM works
    JOIN genres ON works.ID=genres.work_id
    WHERE genres.genre LIKE ?|);

    # works._list_by_title_equal (also applicable for title_contains
    # for which the client is responsible for supplying wildcards)
    $schema{works}->{_list_by_title_equal} =
	$dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN titles ON works.ID=titles.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE ((titles.title LIKE ?) OR (titles.transliteration LIKE ?) OR (works.uniform_title LIKE ?)) AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    GROUP BY works.ID
    ORDER BY uniform_title ASC|);

    # works._list_by_title_not_equal
    $schema{works}->{_list_by_title_not_equal} =
	$dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN titles ON works.ID=titles.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE ((titles.title NOT LIKE ?) OR (titles.transliteration NOT LIKE ?) OR (works.uniform_title NOT LIKE ?)) AND (catalogues.label = "Op." OR catalogues.label IS NULL)
    GROUP BY works.ID
    ORDER BY uniform_title ASC|);

    # works._list_order_by_uniform_title
    $schema{works}->{_list_order_by_uniform_title} =
	$dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number, REPLACE(UPPER(uniform_title),"'","") AS uniform_title_sortable FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN titles ON works.ID=titles.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE (catalogues.label = "Op." OR catalogues.label IS NULL)
    GROUP BY works.ID
    ORDER BY uniform_title_sortable ASC|);

    # works._list_order_by_opus_number
    $schema{works}->{_list_order_by_opus_number} =
	$dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number, REPLACE(UPPER(uniform_title),"'","") AS uniform_title_sortable FROM works
    LEFT JOIN composition ON works.ID=composition.work_id
    LEFT JOIN titles ON works.ID=titles.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE catalogues.label = "Op."
    GROUP BY works.ID
    ORDER BY catalogue_numbers.number_position ASC|);

    # works._list_order_by_year
    $schema{works}->{_list_order_by_year} =
	$dbh->prepare(q|SELECT works.*, end.year AS year, catalogues.label AS catalogue, catalogue_numbers.number AS catalogue_number, REPLACE(UPPER(uniform_title),"'","") AS uniform_title_sortable FROM works
    JOIN composition ON works.ID=composition.work_id
    LEFT JOIN titles ON works.ID=titles.work_id
    LEFT JOIN dates AS end ON composition.period_end=end.ID
    LEFT JOIN catalogue_numbers ON catalogue_numbers.work_id=works.ID
    LEFT JOIN catalogues ON catalogue_numbers.catalogue_id = catalogues.ID
    WHERE (catalogues.label = "Op." OR catalogues.label IS NULL)
    GROUP BY works.ID
    ORDER BY year ASC|);
    
    ######################################################################################################
    ### ARCHIVES TABLE STATEMENTS
    ######################################################################################################

    # archives._full
    $schema{archives}->{_full} =
	$dbh->prepare(q|SELECT archives.ID, archives.title, archives.abbreviation, | . date_selector('established') . q|,
    | . date_selector('disbanded') . q|, archives.city, archives.location, archives.country, archives.uri, archives.telephone,
    archives.email, archives.latitude, archives.longitude, archives.notes
    FROM archives
    LEFT JOIN dates AS established ON archives.date_established = established.ID
    LEFT JOIN dates AS disbanded ON archives.date_disbanded = disbanded.ID
    WHERE archives.ID=?|);

    $schema{archives}->{_letters} =
	$dbh->prepare(q|SELECT letters.ID, | . date_selector('composed') . ', ' . date_selector('sent') . q|,
    addressee.given_name AS addressee_given_name, addressee.family_name AS addressee_family_name, signatory.given_name AS signatory_given_name,
    addressee.family_name AS signatory_family_name, letters.original_text, letters.english_text,
    in_archive.archival_ref_str, in_archive.archival_ref_num, in_archive.date_acquired, in_archive.date_released, in_archive.access,
    in_archive.item_status, in_archive.copy_type, in_archive.copyright, in_archive.notes
    FROM letters
    JOIN in_archive ON in_archive.entity_id = letters.ID
    LEFT JOIN dates AS composed ON letters.date_composed = composed.ID
    LEFT JOIN dates AS sent ON letters.date_sent = sent.ID
    LEFT JOIN persons AS addressee ON letters.addressee = addressee.ID
    LEFT JOIN persons AS signatory ON letters.signatory = signatory.ID
    WHERE in_archive.entity_type = "letters" AND in_archive.archive_id=?
    ORDER BY in_archive.archival_ref_num, in_archive.archival_ref_str, composed.year, composed.month, composed.day|);

    $schema{archives}->{_manuscripts} =
	$dbh->prepare_cached(q|SELECT manuscripts.ID, manuscripts.title, manuscripts.purpose, manuscripts.physical_size,
    manuscripts.medium, manuscripts.extent, manuscripts.missing, | . date_selector('made') . q|, manuscripts.annotation_of,
    in_archive.archival_ref_str, in_archive.archival_ref_num, in_archive.date_acquired, in_archive.date_released, in_archive.access,
    in_archive.item_status, in_archive.copy_type, in_archive.copyright, in_archive.notes, works.uniform_title, manuscripts.work_id
    FROM manuscripts
    JOIN in_archive ON in_archive.entity_id = manuscripts.ID
    LEFT JOIN works ON manuscripts.work_id = works.ID
    LEFT JOIN dates AS made ON manuscripts.date_made = made.ID
    -- LEFT JOIN editions AS annotated_edition ON manuscripts.annotation_of = annotated_edition.ID
    WHERE in_archive.entity_type = "manuscripts" AND in_archive.archive_id=?
    ORDER BY in_archive.archival_ref_num, in_archive.archival_ref_str, made.year, made.month, made.day, manuscripts.title, manuscripts.purpose|);

    $schema{archives}->{_complete} = {details            => ['ONE', '_full'],
				      letter             => ['MANY', '_letters'],
				      manuscript         => ['MANY', '_manuscripts']};

    ######################################################################################################
    ### PERIOD STATEMENTS
    ######################################################################################################

    $schema{period}->{_composition_start} =
	$dbh->prepare_cached(q|SELECT composition.ID, manuscripts.title AS manuscript_title, | . date_selector("start") . q|, composition.work_type, works.uniform_title, works.sub_title, composition.work_id
    FROM composition
    JOIN works ON composition.work_id = works.ID
    LEFT JOIN dates AS start ON composition.period_start = start.ID
    LEFT JOIN manuscripts ON composition.manuscript_id = manuscripts.ID
    WHERE start.year = ?
    ORDER BY start.year, start.month, start.day, composition.work_type|);

    $schema{period}->{_composition_end} =
	$dbh->prepare_cached(q|SELECT composition.ID, manuscripts.title AS manuscript_title, | . date_selector("end") . q|, composition.work_type, works.uniform_title, works.sub_title, composition.work_id
    FROM composition
    JOIN works ON composition.work_id = works.ID
    LEFT JOIN dates AS end ON composition.period_end = end.ID
    LEFT JOIN manuscripts ON composition.manuscript_id = manuscripts.ID
    WHERE end.year = ?
    ORDER BY end.year, end.month, end.day, composition.work_type|);

    $schema{period}->{_manuscripts} =
	$dbh->prepare_cached(q|SELECT manuscripts.ID, manuscripts.title, manuscripts.purpose, manuscripts.physical_size,
    manuscripts.medium, manuscripts.extent, manuscripts.missing, | . date_selector('made') . q|, manuscripts.annotation_of,
    manuscripts.notes, archives.ID AS archive_id, archives.abbreviation AS archive_abbr, archives.title AS archive
    FROM manuscripts
    JOIN dates AS made ON manuscripts.date_made = made.ID
    LEFT JOIN in_archive ON in_archive.entity_id = manuscripts.ID
    LEFT JOIN archives ON in_archive.archive_id = archives.ID
    WHERE made.year = ? AND (in_archive.entity_type = "manuscripts" OR in_archive.entity_type IS NULL)
    ORDER BY made.year, made.month, made.day, manuscripts.purpose|);

    # FIXME Find a good abstraction for binding a single argument to
    # multiple placeholders. The is called from Database::AUTOLOAD.
    $schema{period}->{_letters} =
	$dbh->prepare_cached(q|SELECT letters.ID, | . date_selector('composed') . ', ' . date_selector('sent') . q|, addressee.ID AS addressee_id,
    addressee.given_name AS addressee_given_name, addressee.family_name AS addressee_family_name, signatory.ID AS signatory_id,
    signatory.given_name AS signatory_given_name, signatory.family_name AS signatory_family_name
    FROM letters
    LEFT JOIN dates AS composed ON letters.date_composed = composed.ID
    LEFT JOIN dates AS sent ON letters.date_sent = sent.ID
    LEFT JOIN persons AS addressee ON letters.addressee = addressee.ID
    LEFT JOIN persons AS signatory ON letters.signatory = signatory.ID
    -- WHERE composed.year = ? OR sent.year = ?
    WHERE composed.year = ?
    ORDER BY composed.year, composed.month, composed.day|);

    $schema{period}->{_performances} =
	$dbh->prepare_cached(q|SELECT performances.ID, | . date_selector('performed') . q|, venues.name AS venue, venues.city,
    venues.country, venues.venue_type, performances.performance_type, performances.notes, works.uniform_title, works.ID AS work_id
    FROM performances
    JOIN dates AS performed ON performances.date_performed = performed.ID
    JOIN works ON performances.work_id = works.ID
    LEFT JOIN venues ON performances.venue_id = venues.ID
    WHERE performed.year = ?
    ORDER BY performed.year, performed.month, performed.day|);

    $schema{period}->{_publications} =
	$dbh->prepare_cached(q|SELECT publications.ID, publications.title, publications.publisher,
    publications.publication_place, | . date_selector('pub_date') . q|, publications.serial_number, publications.score_type,
    publications.notes, published_in.edition_extent, published_in.publication_range, works.ID AS work_id, works.uniform_title
    FROM publications
    JOIN published_in ON published_in.publication_id = publications.ID
    JOIN editions ON published_in.edition_id = editions.ID
    JOIN works ON editions.work_id = works.ID
    JOIN dates AS pub_date ON publications.date_published = pub_date.ID
    WHERE pub_date.year = ?
    ORDER BY pub_date.year, pub_date.month, pub_date.day|);

    $schema{period}->{_complete} = { composition_start => ['MANY', '_composition_start'],
				     composition_end   => ['MANY', '_composition_end'],
				     manuscript        => ['MANY', '_manuscripts'],
				     letter            => ['MANY', '_letters'],
				     performance       => ['MANY', '_performances'],
				     publication       => ['MANY', '_publications'] };
}

#################################################################################################################
#### FIELD VALUE EXPLANATIONS
#################################################################################################################

our $explanations = {
    manuscripts => {
	purpose => [{ pattern     => qr|^sketch$|,
		      description => 'Sketch',
		      position    => 'end' },
		    { pattern     => qr|^contextualised sketch$|,
		      description => 'Contextualised Sketch',
		      position    => 'end' },
		    { pattern     => qr|^draft short/piano score$|,
		      description => 'Draft Short/Piano Score',
		      position    => 'end' },
		    { pattern     => qr|^extended draft short score$|,
		      description => 'Extended Draft Short Score',
		      position    => 'end' },
		    { pattern     => qr|^instrumental annotations$|,
		      description => 'Instrumental Annotations',
		      position    => 'end' },
		    { pattern     => qr|^draft full score$|,
		      description => 'Draft Full Score',
		      position    => 'end' },
		    { pattern     => qr|^autograph complete full score$|,
		      description => 'Autograph Complete Full Score',
		      position    => 'end' },
		    { pattern     => qr|^annotated published score$|,
		      description => 'Annotated Published Score',
		      position    => 'end' }] },

    titles => {
	language => [{ pattern     => qr|^en$|,
		       description => 'English',
		       position    => 'end' },
		     { pattern     => qr|^fr$|,
		       description => 'French',
		       position    => 'end' },
		     { pattern     => qr|^ru$|,
		       description => 'Russian',
		       position    => 'end' }] }

    };

$explanations->{composition} = { work_type => $explanations->{manuscripts}->{purpose} };
    
1;
