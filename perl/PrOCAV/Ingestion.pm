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
my %look_up_columns = ();
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
    $cell_formats{unlocked}    = $workbook->add_format(locked => 0);
    $cell_formats{locked}      = $workbook->add_format(locked => 1);
    $cell_formats{column_name} = $workbook->add_format(locked => 1, bg_color => 'grey', pattern => 1);

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

    # add the look-ups
    #populate_look_ups();

    $workbook->close() or die("Could not close workbook file: $filename\n");
}

sub add_look_ups {
    my ($table, $sheet, $first_col) = @_;
    
    #my $look_ups_sheet = $workbook->add_worksheet("lookups");
    #$look_ups_sheet->protect("password");

    my $dbh = Database::make_dbh();

    $look_up_columns{$table} = {};

    my $look_up_count = 0;
    foreach my $name (Database::registered_look_ups()) {
	my $proc = Database::find_look_up($name);
	my $col = $first_col + $look_up_count;

	# $stmt could be either a DBI prepared statement or a list of
	# hashes. So ->execute it only if it's the former.
	my $stmt = &$proc($dbh);
	$stmt->execute() unless (ref $stmt ne "DBI::st");

	# to get the next look_up, use fetchrow if $stmt is a prepared
	# statement, or use an index if it's a list
	my $row = 0;
	while (my $look_up = (ref $stmt eq "DBI::st") ? $stmt->fetchrow_hashref() : $stmt->[$row]) {
	    $sheet->write($row,
			  $col,
			  sprintf("%s [%s]", $look_up->{display}, $look_up->{value}),
			  $cell_formats{locked});

	    $row++;
	}

	# set the columns to hidden and locked
	$sheet->set_column($col, $col, undef, $cell_formats{locked}, 0);

	# store the association of this look-up with this column for
	# this table
	$look_up_columns{$table}->{$name} =
	    Excel::Writer::XLSX::Utility::xl_rowcol_to_cell(0, $col) . ":" .
	    Excel::Writer::XLSX::Utility::xl_rowcol_to_cell($row, $col);

	$look_up_count++;
    }
}

sub create_sheet {
    my $table = shift;

    my $sheet = $workbook->add_worksheet($table);

    $sheet->protect("password");

    # add look-ups
    add_look_ups($table, $sheet, $#{ Database::table_info($table)->{_field_order} } + 1);

    # configure the columns
    while (my ($col, $field_name) = each @{ Database::table_info($table)->{_field_order} }) {
	add_column($table, $field_name, $sheet, $col);
    }
}

sub add_column {
    my ($table, $field_name, $sheet, $col) = @_;
    my $field_info = Database::table_info($table)->{$field_name};
    if (not defined $field_info) { die "Could not find schema for $table.$field_name\n"; }

    # set column properties
    $sheet->set_column($col,
		       undef, #$field_info->{cell_width},
		       ($field_info->{access} eq "ro") ? $cell_formats{locked} : $cell_formats{unlocked});

    if ($field_info->{data_type} eq "integer") {
    	$sheet->data_validation(1, $col, $MAX_RECORDS, $col, {validate => 'integer',
    							      criteria => '>=',
    							      value    => 0});
    } elsif ($field_info->{data_type} eq "decimal") {
    	$sheet->data_validation(1, $col, $MAX_RECORDS, $col, {validate => 'decimal',
    							      criteria => '>=',
    							      value    => 0});
    } elsif ($field_info->{data_type} eq "look_up") {
    	$sheet->data_validation(1, $col, $MAX_RECORDS, $col, {validate => 'list',
    							      value    => "=" . $look_up_columns{$table}->{$field_info->{look_up}}});
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
