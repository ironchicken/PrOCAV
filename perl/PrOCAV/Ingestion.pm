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
use Database qw($schema);

package Ingestion;

sub create_workbook {
    my $include_records = shift;

    while (my ($table, $IDs) = each %$include_records) {
	my $sheet = create_sheet($table);
	
	my $row = 1;
	foreach my $ID ($IDs) {
	    push_record($sheet, $row, $table, $ID);
	    $row++;
	}
    }
};

sub create_sheet {
    my $table = shift;

    my $sheet;

    $sheet->protect("password");
}

sub push_record {
    my ($sheet, $row, $table, $ID) = @_;

    my $unlocked  = $workbook->add_format(locked => 0);
    my $locked  = $workbook->add_format(locked => 1);

    my $record = get_record($table, $ID);
    if (defined $record) {
	my $col = 'A';
	while (my ($field, $value) = each %$record) {
	    my $field_props = $Database::schema{$table}->{$field};

	    if ($field_props->{access} eq "ro") {
		$sheet->write("$col$row", $value, $locked);
	    } elsif ($field_props->{access} eq "rw") {
		$sheet->write("$col$row", $value, $unlocked);
	    }
	}
    }
}

1;
