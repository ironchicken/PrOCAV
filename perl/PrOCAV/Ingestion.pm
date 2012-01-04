#
# PrOCAV
#
# This module provides functions to ingest data from Excel
# spreadsheets and to prepare template spreadsheets for data entry.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use DBI;
#use Spreadsheet::WriteExcel;
#use Spreadsheet::WriteExcel::Utility;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
#use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
#use Text::Iconv;
use PrOCAV::Database qw(make_dbh find_look_up registered_look_ups is_look_up table_order table_info record_stmt spare_IDs);
use File::Temp qw(tempfile);
use List::Util qw(max min);
use List::MoreUtils qw(first_index);

package Ingestion;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(create_workbook);

my $workbook;
my $MAX_RECORDS = 1000;

# package-local cell formats
my %cell_formats = ();

sub create_workbook {
    my $include_records = shift;

    my ($fh, $filename) = File::Temp::tempfile();
    $workbook = Excel::Writer::XLSX->new($filename);
    #$workbook = Spreadsheet::WriteExcel->new($filename);

    if (not defined $workbook) {
	die("Could not create workbook file: $filename\n");
    }

    # create some formats
    $cell_formats{unlocked}    = $workbook->add_format(); $cell_formats{unlocked}->set_locked(0);
    $cell_formats{field_value} = $workbook->add_format(text_wrap => 1, ); $cell_formats{field_value}->set_locked(0);
    $cell_formats{locked}      = $workbook->add_format(locked => 1, bg_color => 'silver');
    $cell_formats{column_name} = $workbook->add_format(locked => 1, bg_color => 'grey', bold => 1, center_across => 1, shrink => 1);

    my $dbh = Database::make_dbh();

    # add the look-ups
    create_look_ups($dbh);

    # create worksheets for the tables
    foreach my $table (Database::table_order()) {
	my $sheet = create_sheet($table);

	# add any requested records
	my $row = 1;
	if (exists $include_records->{$table}) {
	    my $get_stmt = Database::record_stmt($table);
	    foreach my $ID (@{ $include_records->{$table} }) {
		push_record($sheet, $row, $get_stmt, $table, $ID);
		$row++;
	    }
	}

	# if applicable, fill in spare IDs in remaining rows
	if (exists Database::table_info($table)->{ID}) {
	    my @spare_IDs = Database::spare_IDs($dbh, $table);
	    my $next = List::Util::max(@spare_IDs) + 1 || 1;
	    foreach my $r ($row..$MAX_RECORDS) {
		#$sheet->write($r, List::MoreUtils::first_index { $_ eq "ID" } keys %{ Database::table_info($table) }, pop @spare_IDs || $next++);
		$sheet->write($r, 0, pop @spare_IDs || $next++);
	    }
	}
    }

    # hide the lookups sheet and activate works

    # FIXME In localc, the works sheet cells are read-only until
    # another sheet has been visited.
    my ($lookups, $works) = $workbook->sheets(0, 1);
    $works->activate();
    $works->set_first_sheet();
    $lookups->hide();
    
    $workbook->close() or die("Could not close workbook file: $filename\n");

    return $filename;
}

sub create_look_ups {
    my $dbh = shift or Database::make_dbh();

    my $look_ups_sheet = $workbook->add_worksheet("lookups");
    $look_ups_sheet->protect("password");

    my $look_up_count = 0;
    foreach my $name (Database::registered_look_ups()) {
	my $proc = Database::find_look_up($name);
	my $col = $look_up_count;

	# $stmt could be either a DBI prepared statement or a list of
	# hashes. So ->execute it only if it's the former.
	my $stmt = &$proc($dbh);
	$stmt->execute() unless (ref $stmt ne "DBI::st");

	# to get the next look_up, use fetchrow if $stmt is a prepared
	# statement, or use an index if it's a list
	my $row = 0;
	while (my $look_up = (ref $stmt eq "DBI::st") ? $stmt->fetchrow_hashref() : $stmt->[$row]) {
	    $look_ups_sheet->write($row,
			  $col,
			  sprintf("%s [%s]", $look_up->{display}, $look_up->{value}),
			  $cell_formats{locked});

	    $row++;
	}

	# set the columns to hidden and locked
	$look_ups_sheet->set_column($col, $col, undef, $cell_formats{locked}, 0);

	# create a named range for this look-up
	$workbook->define_name($name, "=lookups!" .
	    Excel::Writer::XLSX::Utility::xl_rowcol_to_cell(0, $col, 1, 1) . ":" .
	    #Spreadsheet::WriteExcel::Utility::xl_rowcol_to_cell(0, $col, 1, 1) . ":" .
	    Excel::Writer::XLSX::Utility::xl_rowcol_to_cell($row, $col, 1, 1));
	    #Spreadsheet::WriteExcel::Utility::xl_rowcol_to_cell($row, $col, 1, 1));

	$look_up_count++;
    }
}
    
sub create_sheet {
    my $table = shift;

    my $sheet = $workbook->add_worksheet($table);

    #$sheet->protect("password");

    # configure the columns
    while (my ($col, $field_name) = each @{ Database::table_info($table)->{_field_order} }) {
	add_column($table, $field_name, $sheet, $col);
    }

    # set row heights
    foreach my $row (1..$MAX_RECORDS) {
	$sheet->set_row($row, 20);
    }

    return $sheet;
}

sub add_column {
    my ($table, $field_name, $sheet, $col) = @_;
    my $field_info = Database::table_info($table)->{$field_name};
    if (not defined $field_info) { die "Could not find schema for $table.$field_name\n"; }

    # first check that the combination of options supplied is valid

    # set column properties
    $sheet->set_column($col, $col,
		       $field_info->{cell_width},
		       ($field_info->{access} eq "ro") ? $cell_formats{locked} : $cell_formats{unlocked});

    # set field properties for this column for MAX_RECORDS rows
    foreach my $row (1..$MAX_RECORDS) {
	# if the access property is "ro" set the cell as locked
	$sheet->write($row, $col, undef, ($field_info->{access} eq "ro") ? $cell_formats{locked} : $cell_formats{unlocked});

	# set validation criteria for the data type
	if ($field_info->{data_type} eq "integer") {
	    my $validation = {validate => 'integer'};
	    if (exists $field_info->{minimum} and exists $field_info->{maximum}) {
		$validation->{criteria} = 'between';
		$validation->{minimum} = $field_info->{minimum};
		$validation->{maximum} = $field_info->{maximum};
	    } elsif (exists $field_info->{minimum}) {
		$validation->{criteria} = '>=';
		$validation->{value} = $field_info->{value};
	    } elsif (exists $field_info->{maximum}) {
		$validation->{criteria} = '<=';
		$validation->{value} = $field_info->{value};
	    } elsif (exists $field_info->{foreign_key}) {
		$validation->{criteria} = '>=';
		$validation->{value} = 0;
		$validation->{input_title} = "Foreign key: " . $field_info->{foreign_key};
		$validation->{input_message} = $field_info->{hint};
	    } else {
		$validation->{criteria} = '>=';
		$validation->{value} = 0;
	    }

	    $sheet->data_validation($row, $col, $validation);
	} elsif ($field_info->{data_type} eq "decimal") {
	    $sheet->data_validation($row, $col, {validate => 'decimal',
						 criteria => '>=',
						 value    => 0});
	} elsif ($field_info->{data_type} eq "boolean") {
	    $sheet->data_validation($row, $col, {validate => 'list',
						 value    => [qw(yes no)]});
	} else {
	    if (exists $field_info->{foreign_key}) {
		$sheet->data_validation($row, $col, {validate      => 'any',
						     input_title   => "Foreign key: " . $field_info->{foreign_key},
						     input_message => $field_info->{hint}});
	    }
	}

	# set the column width
	if (exists $field_info->{width}) {
	    $sheet->data_validation($row, $col, {validate => 'length',
						 criteria => '<=',
						 value    => $field_info->{width}});
	}
    }

    # make look-up fields' cells use data validation
    if ($field_info->{data_type} eq "look_up") {
	$sheet->data_validation(1, $col, $MAX_RECORDS, $col,
				{validate => 'list',
				 source   => $field_info->{look_up}});
    }

    # add field name
    $sheet->write_string(0, $col, $field_name, $cell_formats{column_name});
    
}

sub push_record {
    my ($sheet, $row, $stmt, $table, $ID) = @_;

    $stmt->execute($ID);
    my $record = $stmt->fetchrow_hashref();

    if (defined $record) {
	while (my ($col, $field_name) = each @{ Database::table_info($table)->{_field_order} }) {
	    $sheet->write($row, $col, $record->{$field_name});
	}
    }
}

sub ingest_workbook {
    my $dbh; my $workbook_filename;
    if (@_ == 2) {
	($dbh, $workbook_filename) = @_;
    } elsif (@_ == 1) {
	$workbook_filename = shift;
	$dbh = Database::make_dbh();
    }

    #my $converter = Text::Iconv->new("utf-8", "windows-1251");
    #my $workbook = Spreadsheet::XLSX->new($workbook_filename, $converter);
    my $workbook = Spreadsheet::XLSX->new($workbook_filename);
    #my $workbook = Spreadsheet::ParseExcel->new($workbook_filename, $converter);

    if (not defined $workbook) { die("Could not parse $workbook_filename\n"); }

    foreach my $table (Database::table_order()) {
	ingest_worksheet($dbh, $workbook, $table, $workbook->worksheet($table)) or die("Could not parse sheet $table\n");
    }
}

# parse_look_up_value takes a text string as found in a look-up cell
# value and returns the field value from that string
sub parse_look_up_value { @_[0] =~ /.*\[([^\]]+)\]$/; $1; }

use Data::Dumper;
$Data::Dumper::Indent = 0;

sub ingest_worksheet {
    my ($dbh, $workbook, $table, $sheet) = @_;

    print "+ $table...\n";

    if (not defined $sheet) {
	print "Ignoring unavailable table $table\n";
	return 1;
    }

    my ($row_min, $row_max) = $sheet->row_range();
    my ($col_min, $col_max) = $sheet->col_range();

    # check that all the columns are present and are in the right
    # order
    while (my ($col, $head) = each @{ Database::table_info($table)->{_field_order} }) {
	next unless ($sheet->get_cell($row_min, $col)->value() ne $head);
	die("In sheet for $table, column #$col should be '$head', got " . $sheet->get_cell($row_min, $col)->value());
    }

    foreach my $row ($row_min + 1 .. $row_max) {
	# make a hash of the current row, mapping column (field) names
	# to the values in the row
	print "| + $row:\n";
	my %record;
	while (my ($col, $field_name) = each @{ Database::table_info($table)->{_field_order} }) {
	    my $cell = $sheet->get_cell($row, $col);
	    if (defined $cell) {
		if (Database::is_look_up($table, $field_name)) { $record{$field_name} = parse_look_up_value($cell->value()); }
		else { $record{$field_name} = $cell->value(); }
	    } else { $record{$field_name} = undef; }
	}

	#if (Database::record_empty($table, \%record)) {
	#    print "| | $row is EMPTY, so stopping:\n" . Dumper(\%record) . "\n";
	#} else {
	#    print "| | $row is NOT empty:\n" . Dumper(\%record) . "\n";
	#}

	last if (Database::record_empty($table, \%record));

	# update or insert the record
	if (Database::record_different($table, \%record)) {
	    Database::update_record(($table, \%record));
	    print "| | Updated $table " . Dumper(\%record) . "\n";
	} elsif (not Database::record_exists($table, \%record)) {
	    Database::insert_record(($table, \%record));
	    print "| | Inserted $table " . Dumper(\%record) . "\n";
	}
    }

    return 1;
}

1;
