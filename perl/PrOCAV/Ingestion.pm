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
use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Utility;
use Database qw(make_dbh schema look_ups);
use File::Temp qw(tempfile);
use base 'Exporter';

package Ingestion;

our @EXPORT = qw(create_workbook);

my $workbook;
my %look_up_columns = ();

# package-local cell formats
my $unlocked;
my $locked;

sub create_workbook {
    my $include_records = shift;

    my ($fh, $filename) = tempfile();
    $workbook = Spreadsheet::WriteExcel->new($filename);

    if (not defined $workbook) {
	die("Could not create workbook file: $filename\n");
    }

    # create some formats
    $unlocked = $workbook->add_format(locked => 0);
    $locked = $workbook->add_format(locked => 1);

    while (my ($table, $IDs) = each %$include_records) {
	my $sheet = create_sheet($table);
	
	my $row = 1;
	foreach my $ID ($IDs) {
	    push_record($sheet, $row, $table, $ID);
	    $row++;
	}
    }

    $workbook->close() or die("Could not close workbook file: $filename\n");
}

sub populate_look_ups {
    my $look_ups_sheet = $workbook->add_worksheet("lookups");
    $look_ups_sheet->protect("password");

    my $dbh = make_dbh();

    my $look_up_count = 0;
    while (my ($name, $proc) = each %Database::look_ups) {
	# store the association of this look-up with this column
	$look_up_columns[$name] = xl_rowcol_to_cell(0, $look_up_count * 2);

	# $stmt could be either a DBI prepared statement or a list of
	# hashes. So ->execute it only if it's the former.
	my $stmt = &$proc($dbh);
	$stmt->execute() unless (ref $stmt ne "DBI::st");

	# to get the next look_up, use fetchrow if $stmt is a prepared
	# statement, or use an index if it's a list
	my $row = 1;
	while (my $look_up = (ref $stmt eq "DBI::st") ? $stmt->fetchrow_hashref() : $stmt->[$row - 1]) {
	    $look_ups_sheet->write($row,
				   $look_up_count * 2,
				   $look_up->{value},
				   $locked);

	    $look_ups_sheet->write($row,
				   ($look_up_count * 2) + 1,
				   $look_up->{display},
				   $locked);

	    $row++;
	}
	$look_up_count++;
    }
}

sub create_sheet {
    my $table = shift;

    my $sheet = $workbook->add_worksheet($table);

    $sheet->protect("password");

}

sub push_record {
    my ($sheet, $row, $table, $ID) = @_;

    my $record = get_record($table, $ID);
    if (defined $record) {
	my $col = 'A';
	while (my ($field, $value) = each %$record) {
	    my $field_props = Database::schema{$table}->{$field};

	    my $format = ($field_props->{access} eq "ro") ? $locked : $unlocked;

	    if ($field_props->{data_type} eq "string") {
		$sheet->write_string("$col$row", $value, $format);
	    } elsif ($field_props->{data_type} eq "number") {
		$sheet->write_number("$col$row", $value, $format);
	    }
	}
    }
}

1;
