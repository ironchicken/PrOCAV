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
use PrOCAV::Database qw(make_dbh find_look_up registered_look_ups table_order table_info);
use File::Temp qw(tempfile);

package Ingestion;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(create_workbook);

my $workbook;
my $MAX_RECORDS = 100;

# package-local cell formats
my %cell_formats = ();

sub create_workbook {
    my $include_records = shift;

    my ($fh, $filename) = File::Temp::tempfile();
    $workbook = Excel::Writer::XLSX->new($filename);

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
	if (exists $include_records->{$table}) {
	    my $row = 0;
	    foreach my $ID ($include_records->{$table}) {
		push_record($sheet, $row, $table, $ID);
		$row++;
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
	    Excel::Writer::XLSX::Utility::xl_rowcol_to_cell($row, $col, 1, 1));

	$look_up_count++;
    }
}
    
sub create_sheet {
    my $table = shift;

    my $sheet = $workbook->add_worksheet($table);

    $sheet->protect("password");

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
	    $sheet->data_validation($row, $col, {validate => 'integer',
						 criteria => '>=',
						 value    => 0});
	} elsif ($field_info->{data_type} eq "decimal") {
	    $sheet->data_validation($row, $col, {validate => 'decimal',
						 criteria => '>=',
						 value    => 0});
	} elsif ($field_info->{data_type} eq "boolean") {
	    $sheet->data_validation($row, $col, {validate => 'list',
						 value    => [qw(yes no)]});
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
    my ($sheet, $row, $table, $ID) = @_;

    my $record = get_record($table, $ID);
    if (defined $record) {
	my $col = 0;
	while (my ($field, $value) = each %$record) {
	    my $field_props = Database::table_info($table)->{$field};

	    my $format = ($field_props->{access} eq "ro") ? $cell_formats{locked} : $cell_formats{unlocked};

	    if ($field_props->{data_type} eq "string") {
		$sheet->write_string($row, $col, $value, $format);
	    } elsif ($field_props->{data_type} eq "number") {
		$sheet->write_number($row, $col, $value, $format);
	    }

	    $col++;
	}
    }
}

1;
