#
# PrOCAV
#
# This module provides prepared statements and other useful functions
# for working with the PrOCAV database.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package PrOCAV::Database;

use strict;
use DBI;
use List::Util qw(max min);
use Array::Utils qw(:all);
use AutoLoader;
#use PrOCAV::Schema qw(%look_ups @table_order %schema);
#lib 'PrOCAV';
use PrOCAV::Schema;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(make_dbh record_stmt record all_records insert_record insert_resource
  find_look_up is_look_up registered_look_ups table_info table_order session create_session spare_IDs
  record_empty record_different record_exists update_record);
our $AUTOLOAD;

my %db_attrs = (RaiseError  => 1,
		PrintError  => 0);

my %db_opts = (database => "DBI:mysql:procav",
	       user     => "root",
	       password => "tbatst",
	       attrs    => \%db_attrs);

sub make_dbh {
    my $dbh = DBI->connect_cached($db_opts{database},
			$db_opts{user},
			$db_opts{password})
	or die ("Could not connect to database.\n");

    $dbh->{'mysql_enable_utf8'} = 1;
    $dbh->do('SET NAMES utf8');

    prepare_statements($dbh);

    return $dbh;
}

sub registered_look_ups {
    keys %look_ups;
}

sub find_look_up {
    my $look_up_name = shift;
    $look_ups{$look_up_name};
}

sub is_look_up {
    my ($table, $field_name) = @_;
    $schema{$table}->{$field_name}->{data_type} eq "look_up";
}

sub table_order {
    @table_order;
}

sub table_info {
    my $table_name = shift;
    $schema{$table_name};
}

#################################################################################################################
#### PREPARED SQL STATEMENTS
#################################################################################################################

use Data::UUID;
use Text::Sprintf::Named;

my $get_session_stmt;
my $check_editor_credentials_stmt;
my $create_session_stmt;

sub prepare_statements {
    my $dbh = shift;

    # REMEBER You can trace statements like this:
    #$schema{$table}->{_match_all}->{TraceLevel} = "2|SQL";

    foreach my $table (@table_order) {
	# prepare _exists statement
	$schema{$table}->{_exists} = $dbh->prepare_cached(
	    sprintf(qq/SELECT %s FROM %s WHERE %s LIMIT 1/,
		    $schema{$table}->{_single_select_field},
		    $table,
		    join(" AND ", map { "$_=?"; } @{ $schema{$table}->{_unique_fields} })));
    
	# prepare _match_all statement
	$schema{$table}->{_match_all} = $dbh->prepare_cached(
	    sprintf(qq/SELECT %s FROM %s WHERE %s LIMIT 1/,
		    $schema{$table}->{_single_select_field},
		    $table,
		    join(" AND ", map { "($_=? OR ($_ IS NULL AND ?=1))"; } @{ $schema{$table}->{_field_order} })));

	# prepare _insert statement
	$schema{$table}->{_insert} = $dbh->prepare_cached(
	    sprintf(qq/INSERT INTO %s (%s) VALUES (%s)/,
		    $table,
		    join(",", @{ $schema{$table}->{_insert_fields} }),
		    join(",", (("?") x scalar @{ $schema{$table}->{_insert_fields} }))));

	# prepare _insert_all_fields statement
	$schema{$table}->{_insert_all_fields} = $dbh->prepare_cached(
	    sprintf(qq/INSERT INTO %s (%s) VALUES (%s)/,
		    $table,
		    join(",", @{ $schema{$table}->{_field_order} }),
		    join(",", (("?") x scalar @{ $schema{$table}->{_field_order} }))));

	# prepare _update statement
	$schema{$table}->{_update} = $dbh->prepare_cached(
	    sprintf(qq/UPDATE %s SET %s WHERE %s/,
		    $table,
		    join(",", map { sprintf("$_=?"); } @{ $schema{$table}->{_insert_fields} }),
		    join(" AND ", map { "$_=?"; } @{ $schema{$table}->{_unique_fields} })));

	# prepare _get statement
	$schema{$table}->{_get} = $dbh->prepare_cached(
	    sprintf(qq/SELECT * FROM %s WHERE %s LIMIT 1/,
		    $table,
		    #join(" AND ", map { "$_=?"; } @{ $schema{$table}->{_unique_fields} })));
		    join(" AND ", map { "($_=? OR ($_ IS NULL AND ?=1))"; } @{ $schema{$table}->{_unique_fields} })));

	# prepare _list statement
	$schema{$table}->{_list} = $dbh->prepare_cached(
	    sprintf(qq/SELECT * FROM %s ORDER BY %s/,
		    $table,
		    join(",", map { "$_ " . $schema{$table}->{_default_order}; } @{ $schema{$table}->{_order_fields} })));

	# prepare _list_ordered statement
	$schema{$table}->{_list_ordered} = Text::Sprintf::Named->new(
	    {fmt => qq/SELECT * FROM $table ORDER BY %(order_by)s %(sort_order)s/});

	# prepare _list_paged statement
	$schema{$table}->{_list_paged} = Text::Sprintf::Named->new(
	    {fmt => qq/SELECT * FROM / .
		 $table .
		 qq/ ORDER BY / .
		 join(",", map { "$_ " . $schema{$table}->{_default_order}; } @{ $schema{$table}->{_order_fields} }) .
		 qq/ LIMIT %(offset)d,%(limit)d/});

	# prepare _list_ordered_paged statement
	$schema{$table}->{_list_ordered_paged} = Text::Sprintf::Named->new(
	    {fmt => qq/SELECT * FROM $table ORDER BY %(order_by)s %(sort_order)s LIMIT %(offset)d,%(limit)d/});

	# prepare _count statement
	$schema{$table}->{_count} = $dbh->prepare_cached(qq/SELECT COUNT(*) AS extent FROM $table/);
    }

    # Statements used for the HTTP interface

    $get_session_stmt = $dbh->prepare_cached(qq/SELECT * FROM sessions WHERE session_type=? AND login_name=? AND session_id=? LIMIT 1/);
    $check_editor_credentials_stmt = $dbh->prepare_cached(qq/SELECT login_name FROM editors WHERE login_name=? AND password=? LIMIT 1/);
    $create_session_stmt = $dbh->prepare_cached(qq/INSERT INTO sessions (session_id, session_type, login_name) VALUES (?,?,?)/);

    # Call the Schema module's prepare_statements subroutine

    schema_prepare_statments($dbh);
}

sub session {
    my ($session_type, $login_name, $session_id) = @_;

    $get_session_stmt->execute($session_type, $login_name, $session_id);

    return defined $get_session_stmt->fetchrow_arrayref;
}

sub create_session {
    my ($session_type, $login_name, $password) = @_;

    if ($session_type eq "editor") {
	$check_editor_credentials_stmt->execute($login_name, $password);
	if (not defined $check_editor_credentials_stmt->fetchrow_arrayref) {
	    return 0;
	}

	my $ug = new Data::UUID;
	my $session_id = $ug->create_str();

	$create_session_stmt->execute($session_id, $session_type, $login_name)
	    or die("Could not create session: " . $create_session_stmt->errstr);

	return $session_id;
    } else { die("Session type $session_type not implemented.\n"); }
}

#################################################################################################################
#### DATA ACCESS/MANIPULATION FUNCTIONS
#################################################################################################################

sub parse_date { }

sub record_stmt {
    $schema{$_[0]}->{_get};
}
    
sub record {
    my ($table, $ID) = @_;

    my $proc = $schema{$table}->{_get};

    if (defined $proc) {
	return $proc->(map { ($_, (defined $_) ? 0 : 1); } @$ID);
    } else {
	warn("No get record procedure for $table.\n");
    }
}

sub record_exists {
    my ($table, $record) = @_;

    $schema{$table}->{_exists}->execute(@{ $record }{@{ $schema{$table}->{_unique_fields} }});
    return defined $schema{$table}->{_exists}->fetchrow_arrayref;
}

sub record_different {
    my ($table, $record) = @_;

    # if the record exists ...
    $schema{$table}->{_exists}->execute(@{ $record }{@{ $schema{$table}->{_unique_fields} }});
    if (defined $schema{$table}->{_exists}->fetchrow_arrayref) {
	# ... but does not match the given $record in *every* field,
	# then return TRUE
	my @args = ();
	foreach my $value (@{ $record }{@{ $schema{$table}->{_field_order} }}) {
	    push @args, ($value, (defined $value) ? 0 : 1);
	}
	$schema{$table}->{_match_all}->execute(@args);

	return not defined $schema{$table}->{_match_all}->fetchrow_arrayref;
    } else {
	# if the record does not exist, return FALSE
	return 0;
    }
}

use Data::Dumper;

sub record_empty {
    my ($table, $record) = @_;

    while (my ($name, $value) = each %{ $record }) {
	return 0 if ((defined $value) && ($name ne "ID"));
    }

    return 1;
}

sub insert_record {
    my ($table, $record, $flags) = @_;

    my $new_record_id;
    if ($flags->{insert_all_fields}) {
	$schema{$table}->{_insert_all_fields}->execute(@{ $record }{@{ $schema{$table}->{_field_order} }})
	    or die $schema{$table}->{_insert_all_fields}->{Statement} . "\n" .
	    Dumper($schema{$table}->{_insert_all_fields}->{ParamValues}) .
	    $schema{$table}->{_insert_all_fields}->errstr;
	if ($new_record_id = $schema{$table}->{_insert_all_fields}->{'mysql_insertid'}) {
	    $record->{ID} = $new_record_id;
	}
    } else {
	$schema{$table}->{_insert}->execute(@{ $record }{@{ $schema{$table}->{_insert_fields} }})
	    or die $schema{$table}->{_insert}->{Statement} . "\n" .
	    Dumper($schema{$table}->{_insert}->{ParamValues}) .
	    $schema{$table}->{_insert}->errstr;
	if ($new_record_id = $schema{$table}->{_insert}->{'mysql_insertid'}) {
	    $record->{ID} = $new_record_id;
	}
    }

    my $dbh = make_dbh;
    if (not $flags->{processing_hook}) {
	# run any update_hooks
	foreach my $fn (@{ $schema{$table}->{_insert_fields} }) {
	    &{ $schema{$table}->{$fn}->{update_hook} }($dbh, "insert", $record)
		if (defined $schema{$table}->{$fn}->{update_hook});
	}
    }

    # run any auto-resource inserters
    foreach my $inserter (@{ $schema{$table}->{_auto_resource_insert} }) {
	&{ $inserter }($dbh, "insert", $record);
    }
    return $new_record_id or 0;
}

sub update_record {
    my ($table, $record, $flags) = @_;

    # first, get a copy of the record as it is before this udate
    my $previous_record = undef;
    if (not $flags->{processing_hook}) {
	$schema{$table}->{_get}->execute(map { ($_, (defined $_) ? 0 : 1); } @{ $record }{@{ $schema{$table}->{_unique_fields} }});
	$previous_record = $schema{$table}->{_get}->fetchrow_arrayref;
    }

    # then update the record
    $schema{$table}->{_update}->execute((@{ $record }{@{ $schema{$table}->{_insert_fields} }},
					 @{ $record }{@{ $schema{$table}->{_unique_fields} }}))
	or die $schema{$table}->{_update}->{Statement} . "\n" .
	Dumper($schema{$table}->{_update}->{ParamValues}) .
	$schema{$table}->{_update}->errstr;

    my $dbh = make_dbh;
    # then process any update_hooks
    if (not $flags->{processing_hook}) {
	foreach my $fn (@{ $schema{$table}->{_insert_fields} }) {
	    &{ $schema{$table}->{$fn}->{update_hook} }($dbh, "update", $record)
		if ((defined $schema{$table}->{$fn}->{update_hook}) &&
		    ($record->{$fn} ne $previous_record->{$fn}));
	}
    }

    # run any auto-resource inserters
    foreach my $inserter (@{ $schema{$table}->{_auto_resource_insert} }) {
	&{ $inserter }($dbh, "update", $record);
    }
    1;
}

sub insert_resource {
    my ($operation, $table, $record, $resource) = @_;

    my $resource_id;
    my $existing_resource = resources($resource->{uri});
    if (not $existing_resource) { #record_exists($table, $record)) {
	$resource_id = insert_record("resources", $resource)
	    or return 0;
    } else {
	$resource_id = $existing_resource->{ID};
    }

    my $about = {resource_id   => $resource_id,
		 related_table => $table,
		 related_id    => $record->{ID}};

    if (not record_exists("resource_about", $about)) {
	insert_record("resource_about", $about)
	    or return 0;
    }
    1;
}

sub spare_IDs {
    my ($dbh, $table) = @_;

    my $st = $dbh->prepare(qq(SELECT ID FROM $table ORDER BY ID));
    $st->execute();
    my @IDs; while (my $row = $st->fetchrow_arrayref) { push @IDs, int($row->[0]); }
    my @range = (List::Util::min(@IDs) .. List::Util::max(@IDs));
    my @spares = Array::Utils::array_diff(@range, @IDs);

    return List::Util::max(@IDs) + 1 if (not @spares);
    return \@spares;
}

sub all_records {
    my $dbh = shift || make_dbh;

    my %tables = ();

    foreach my $table (@table_order) {
	my $records = [];
	$schema{$table}->{_list}->execute();
	while (my $row = $schema{$table}->{_list}->fetchrow_hashref) {
	    push @$records, [@{$row}{@{ $schema{$table}->{_unique_fields} }}];
	}
	if ($records) {
	    $tables{$table} = $records;
	}
    }

    return \%tables;
}

## The PrOCAV::Database modules also exposes subroutines which allow
## access to each table as: TABLE_NAME to retrieve an individual
## record; list_TABLE_NAME to retrieve multiple records;
## insert_TABLE_NAME to insert into TABLE_NAME; struct_TABLE_NAME to
## retrieve a hash of table names and record IDs describing the record
## and its dependencies; complete_TABLE_NAME to retrieve a hash
## containing the record and its dependencies

sub AUTOLOAD {
    my $sub_name = $AUTOLOAD;
    $sub_name =~ s/.*:://;

    my $operation; my $table_name;

    if ($sub_name =~ m/(get|list|count|struct|complete|insert)_(.*)/) {
	($operation, $table_name) = ($1, $2);
    } elsif ($sub_name =~ m/^(get|list|count|struct|complete|insert)$/) {
	$operation = $1;
	$table_name = shift or die("Table name must be supplied.\n");
    } else {
	$table_name = $sub_name;
    }

    my $table = $schema{$table_name} || $schema{$table_name . "s"} || die("No such table: $table_name\n");

    #print Dumper($options);
    #printf("Doing %s on %s (%s); args: %s\n", $operation || "_get", $table_name, $table, join ", ", @_);

    if ((($operation eq "get") || (not defined $operation)) && (@_)) {
	#$table->{_get}->execute(@_);
	$table->{_get}->execute(map { ($_, (defined $_) ? 0 : 1); } @_);
	return $table->{_get}->fetchrow_hashref;

    } elsif ($operation eq "list") {
	my $query = "_list";
	my $st;

	my $options = {};
	for $a (@_) {
	    if ((ref $a eq "HASH") && ((defined $a->{order_by} || defined $a->{sort_order} || defined $a->{offset} || defined $a->{limit}))) {
		$options = $a;
		last;
	    }
	}

	if (defined $options->{order_by} && defined $options->{limit}) {
	    $query = "_list_ordered_paged";
	    $st = make_dbh->prepare($table->{$query}->format({args => {'order_by'   => $options->{order_by},
								       'sort_order' => $options->{sort_order} || "ASC",
								       'offset'     => $options->{offset} || 0,
								       'limit'      => $options->{limit}}}));
	    $st->execute;
	} elsif (defined $options->{limit}) {
	    $query = "_list_paged";
	    $st = make_dbh->prepare($table->{$query}->format({args => {'offset' => $options->{offset} || 0,
								       'limit'  => $options->{limit}}}));
	    $st->execute;
	} elsif (defined $options->{order_by}) {
	    $query = "_list_ordered";
	    $st = make_dbh->prepare($table->{$query}->format({args => {'order_by'   => $options->{order_by},
								       'sort_order' => $options->{sort_order} || "ASC"}}));
	    $st->execute;
	} else {
	    $query = "_list";
	    $st = $table->{$query};
	    $st->execute;
	}

	#print $st->{Statement} . "\n";
	#print Dumper($st->{ParamValues});

	my $rows = [];
	while (my $row = $st->fetchrow_hashref) {
	    push @$rows, $row;
	}
	return $rows;

    } elsif ($operation eq "count") {
	$table->{_count}->execute(@_);
	return $table->{_count}->fetchrow_hashref->{extent};

    } elsif ($operation eq "struct") {
	$table->{_struct}->execute(@_);
	return $table->{_struct}->fetchrow_hashref;
	
    } elsif ($operation eq "complete") {
	my $complete = {};

	while (my ($name, $stmt) = each %{ $table->{_complete} }) {
	    my ($stmt_cardinality, $stmt_name) = @$stmt;

	    $table->{$stmt_name}->execute(@_);
	    if ($stmt_cardinality eq 'ONE') {
		my $record = $table->{$stmt_name}->fetchrow_hashref;
		# only add the record if it exists
		if ($record) {
		    # remove any undef fields
		    foreach my $field (keys %$record) {
			delete $record->{$field} if (not defined $record->{$field});
		    }
		    $complete->{$name} = $record;
		}
	    } elsif ($stmt_cardinality eq 'MANY') {
		$complete->{$name} = ();
		while (my $record = $table->{$stmt_name}->fetchrow_hashref) {
		    # remove any undef fields
		    foreach my $field (keys %$record) {
			delete $record->{$field} if (not defined $record->{$field});
		    }
		    push @{$complete->{$name}}, $record;
		}
		# if no records were added, then delete the list
		if (not defined $complete->{$name}) {
		    delete $complete->{$name};
		}
	    }
	}

	return $complete;

    } elsif ($operation eq "insert") {
	$table->{_insert}->execute(@_);
	return 1;

    } else {
	die("No such operation: $operation; args: " . join(", ", @_) . "\n");
    }
}

1;
