#
# ComposerCat
#
# This module provides prepared statements and other useful functions
# for working with the ComposerCat database.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::Database;

use strict;

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(make_dbh record_stmt record all_records insert_record insert_resource
      find_look_up is_look_up registered_look_ups table_info table_order session create_session spare_IDs
      record_empty record_different record_exists update_record);
}

use DBI;
use List::Util qw(max min);
use Array::Utils qw(:all);
use AutoLoader;
#use ComposerCat::Schema qw(%look_ups @table_order %schema);
#lib 'ComposerCat';
use ComposerCat::Schema;

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

sub table_name {
    my $name = shift;

    return $name if (defined $schema{$name});
    return $name . 's' if (defined $schema{$name . 's'});
    return 0;
}

sub allow_markup {
    my ($element_name) = @_;

    # FIXME Need a more efficient way of doing this.
    while (my ($table_name, $table_schema) = each %schema) {
	return 1 if ($table_schema->{$element_name}->{allow_markup});
    }
    return 0;
}

sub explanations {
    my ($table, $field, $value) = @_;
    $table = table_name($table);

    if (defined $value) {
	if (defined $explanations->{$table}->{$field}) {
	    foreach my $t (@{ $explanations->{$table}->{$field} }) {
		if ($value =~ $t->{pattern}) {
		    return ($t->{description}, $t->{position}, ($t->{position} eq 'inline') ? @+[0] : undef)
		}
	    }
	}
    } else {
	return $explanations->{$table}->{$field};
    }
}

sub table_has_explanations {
    my ($table) = @_;
    $table = table_name($table);

    if (defined $explanations->{$table}) {
	return $explanations->{$table};
    } else {
	return 0;
    }
}

sub field_has_explanations {
    my ($table, $field) = @_;
    $table = table_name($table);

    if (defined $explanations->{$table} && defined $explanations->{$table}->{$field}) {
	return $explanations->{$table}->{$field};
    } else {
	return 0;
    }
}

#################################################################################################################
#### PREPARED SQL STATEMENTS
#################################################################################################################

use Data::UUID;
use Text::Sprintf::Named;

my $get_login_session_stmt;
my $get_public_session_stmt;
my $check_editor_credentials_stmt;
my $create_login_session_stmt;
my $create_public_session_stmt;

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

    $get_login_session_stmt = $dbh->prepare_cached(qq/SELECT * FROM sessions WHERE session_type=? AND login_name=? AND session_id=? LIMIT 1/);
    $get_public_session_stmt = $dbh->prepare_cached(qq/SELECT * FROM sessions WHERE session_type=? AND login_name IS NULL AND session_id=? LIMIT 1/);
    $check_editor_credentials_stmt = $dbh->prepare_cached(qq/SELECT login_name FROM editors WHERE login_name=? AND password=? LIMIT 1/);
    $create_login_session_stmt = $dbh->prepare_cached(qq/INSERT INTO sessions (session_id, session_type, login_name) VALUES (?,?,?)/);
    $create_public_session_stmt = $dbh->prepare_cached(qq/INSERT INTO sessions (session_id, session_type) VALUES (?,?)/);

    # Call the Schema module's prepare_statements subroutine

    schema_prepare_statments($dbh);
}

sub session {
    my ($session_type, $login_name, $session_id) = @_;

    my $st;
    if (not $login_name) {
	$st = $get_public_session_stmt;
	$st->execute($session_type, $session_id);
    } else {
	$st = $get_login_session_stmt;
	$st->execute($session_type, $login_name, $session_id);
    }

    return defined $st->fetchrow_arrayref;
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

	$create_login_session_stmt->execute($session_id, $session_type, $login_name)
	    or die("Could not create session: " . $create_login_session_stmt->errstr);

	return $session_id;
    } elsif ($session_type eq "public") {
	my $ug = new Data::UUID;
	my $session_id = $ug->create_str();

	$create_public_session_stmt->execute($session_id, $session_type)
	    or die("Could not create session: " . $create_public_session_stmt->errstr);

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

## The ComposerCat::Database modules also exposes subroutines which allow
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
	#print Dumper($st->{ParamValues}) . "\n";

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

#################################################################################################################
#### DATA PROCESSING UTILITIES
#################################################################################################################

package ComposerCat::Database::ElementStacking;
use strict;
use XML::SAX::Base;
use base qw(XML::SAX::Base); # FIXME Perhaps try extending Text::WikiFormat::SAX instead?

sub new {
    my $class = shift;
    my %options = @_;

    $options{level} = ['document', 'response', 'content', 'record', 'table', 'field'];

    return bless \%options, $class;
}

sub start_document {
    my ($self, $document) = @_;

    $self->{element_stack} = [];

    $self->SUPER::start_document($document);
}

sub current_level {
    my ($self) = @_;

    return $self->{level}->[scalar @{ $self->{element_stack} }];
}

sub push_element {
    my ($self, $element) = @_;

    push @{ $self->{element_stack} }, $element;

    return $element;
}

sub replace_element {
    my ($self, $new_element) = @_;

    my $replaced_element = pop @{ $self->{element_stack} };

    return $self->push_element($new_element);
}

sub start_element {
    my ($self, $element) = @_;

    if (defined $element) {
	$self->push_element($element);
    }

    $self->SUPER::start_element($self->{element_stack}->[-1]);
}

sub peek_element {
    $_[0]->{element_stack}->[-1];
}

sub pop_element {
    return pop @{ $_[0]->{element_stack} };
}

sub end_element {
    my ($self, $element) = @_;

    my $leaving = $self->pop_element;

    $self->SUPER::end_element($element || _element($leaving->{Name}, 1));
}

sub _element {
    my ($name, $end) = @_;
    return { 
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;
    
    $el->{Attributes}{"{}$name"} = {
	Name => $name,
	LocalName => $name,
	Prefix => "",
	NamespaceURI => "",
	Value => $value,
    };
}

package ComposerCat::Database::MarkupFilter;
use strict;
use XML::SAX::Base;
use base qw(ComposerCat::Database::ElementStacking); # FIXME Perhaps try extending Text::WikiFormat::SAX instead?

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{syntax} = [
	## level 4 heading
	{pattern  => qr|^(?<!=)={4}([^=]+?)={4}(?!=)$|m,
	 element  => ['h6'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 4; }, sub { 4; }]},

	## level 3 heading
	{pattern  => qr|^(?<!=)={3}([^=]+?)={3}(?!=)$|m,
	 element  => ['h5'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 3; }, sub { 3; }]},
	
	## level 2 heading
	{pattern  => qr|^(?<!=)={2}([^=]+?)={2}(?!=)$|m,
	 element  => ['h4'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 2; }, sub { 2; }]},
	
	## level 1 heading
	{pattern  => qr|^(?<!=)=([^=]+?)=(?!=)$|m,
	 element  => ['h3'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 1; }, sub { 1; }]},
	
	## paragraph
	{pattern  => qr|^([^=].+[^=])$|m,
	 element  => ['p'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 0; }, sub { 0; }]},
	
	## strong (bold formatted)
	{pattern  => qr|'{3}(.+?)'{3}|m,
	 element  => ['span', {style => sub { 'font-weight:bold'; }}],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 3; }, sub { 3; }]},
	
	# emphasised (italic formatted)
	{pattern  => qr|(?<!')'{2}([^'].+?)'{2}|m,
	 element  => ['span', {style => sub { 'font-style:italic'; }}],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 2; }, sub { 2; }]},
	
	# [URI link text] link
	{pattern  => qr|\[(http:\S+)\s+([^\]]+)\]|m,
	 element  => ['a', {href => sub { $_[0]; }}],
	 get_text => sub { $_[1]; },
	 padding  => [sub { 2 + length $_[0]; }, sub { 1; }]},

	# [table-name.id link text] link
	{pattern  => qr{\[(works|manuscripts|editions|publications|venues|letters|persons)[/.]([0-9]+)\s+([^\]]+)\]}m,
	 element  => ['a', {href => sub { sprintf "/%s/%s", $_[0], $_[1]; }}],
	 get_text => sub { $_[2]; },
	 padding  => [sub { 2 + length $_[0] . $_[1]; }, sub { 1; }]}
	];

    return bless $self, $class;
}

sub start_element {
    my ($self, $element) = @_;
    #my %attrs = %{$element->{Attributes}};

    $self->{parsing_markup} = ComposerCat::Database::allow_markup ($element->{Name});

    $self->SUPER::start_element($element);
}

sub end_element {
    my ($self, $element) = @_;

    $self->{parsing_markup} = 0;

    $self->SUPER::end_element($element);
}

sub characters {
    my ($self, $chars) = @_;

    if ($self->{parsing_markup}) {
	$self->parse_markup($chars->{Data});
    } else {
	$self->SUPER::characters({Data => $chars->{Data}});
    }
}

sub parse_markup {
    my ($self, $chars) = @_;

    # This is a two-pass operation. The first pass identifies
    # occurrences of the syntax regexes and generates a list of
    # 'skip', 'start_element', and 'end_element' events

    my @events = ();
    foreach my $element_type (@{ $self->{syntax} }) {
	while ($chars =~ /$element_type->{pattern}/g) {
	    # FIXME OK, seriously, how do I get a list of the captured
	    # groups when matching with the global modifier?
	    my @capture_groups = ($1, $2, $3, $4, $5, $6, $7, $8, $9);

	    my %attrs = map { $_ => &{ $element_type->{element}->[1]->{$_} }(@capture_groups) } keys %{ $element_type->{element}->[1] };

	    my $element = {match_start => int @-[0],
			   match_end   => int @+[0],
			   skip_before => &{ $element_type->{padding}->[0] }(@capture_groups),
			   skip_after  => &{ $element_type->{padding}->[1] }(@capture_groups),
			   text        => &{ $element_type->{get_text} }(@capture_groups),
			   tag         => $element_type->{element}->[0],
			   attrs       => \%attrs
	    };

	    push @events, ['skip',
			   $element->{match_start},
			   $element->{match_start} + $element->{skip_before}]
			       unless ($element->{skip_before} == 0);

	    push @events, ['start_element',
			   $element->{match_start} + $element->{skip_before},
			   $element];

	    push @events, ['end_element',
			   $element->{match_end} - $element->{skip_after},
			   $element];

	    push @events, ['skip',
			   $element->{match_end} - $element->{skip_after},
			   $element->{match_end}]
			       unless ($element->{skip_after} == 0);
	}
    }

    # The second pass takes each of those events in order of their
    # position in the source characters and emits the required
    # elements and characters.

    # this will be a pointer to the current position in the characters
    # of the field value string
    my $chars_ptr = 0;

    foreach my $event (sort { $a->[1] <=> $b->[1] } @events ) {
	my $type = shift $event;

	if ($type eq 'skip') {
	    my ($from, $to) = @$event;

	    # consume any characters up to the beginning of the skip
	    $self->SUPER::characters({Data => substr $chars, $chars_ptr, $from - $chars_ptr});

	    # then advance the pointer to the end of the skip
	    $chars_ptr = $to;

	} elsif ($type eq 'start_element') {
	    my ($at, $element) = @$event;

	    # consume any characters up to the beginning of the
	    # element start tag
	    $self->SUPER::characters({Data => substr $chars, $chars_ptr, $at - $chars_ptr});
	    $chars_ptr += ($at - $chars_ptr);

	    # create the element start tag
	    my $el = _element($element->{tag});
	    foreach my $name (keys %{ $element->{attrs} }) {
		_add_attrib($el, $name, $element->{attrs}->{$name});
	    }

	    # and emit it
	    $self->SUPER::start_element($el);

	} elsif ($type eq 'end_element') {
	    my ($at, $element) = @$event;

	    # consume any characters up to the beginning of the
	    # element end tag
	    $self->SUPER::characters({Data => substr $chars, $chars_ptr, $at - $chars_ptr});
	    $chars_ptr += ($at - $chars_ptr);

	    # emit end tag
	    $self->SUPER::end_element;
	} else {
	    die "Invalid event type $type.\n";
	}
    }
}

sub _element {
    my ($name, $end) = @_;
    return { 
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;
    
    $el->{Attributes}{"{}$name"} = {
	Name => $name,
	LocalName => $name,
	Prefix => "",
	NamespaceURI => "",
	Value => $value,
    };
}

package ComposerCat::Database::ValueExplanations;
use strict;
use XML::SAX::Base;
use base qw(ComposerCat::Database::ElementStacking);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    return bless $self, $class;
}

sub start_document {
    my ($self, $document) = @_;

    $self->{explained_table} = 0;
    $self->{explained_field} = 0;

    $self->SUPER::start_document($document);
}

sub start_element {
    my ($self, $element) = @_;
    #my %attrs = %{$element->{Attributes}};

    # Ensure that ElementStacking's push_element is called *first* so
    # that we are at the right level. But don't call start_element yet
    # as, if an explanation needs to be included, it will be appended
    # as an attribute to the element
    $self->SUPER::push_element($element);

    if ($self->current_level eq 'table' && ComposerCat::Database::table_has_explanations ($element->{Name})) {
	$self->{explained_table} = $element->{Name};
	# start_element now because ValueExplanations::characters may
	# not be called
	$self->SUPER::start_element;
    } elsif ($self->current_level eq 'field' && ComposerCat::Database::field_has_explanations ($self->{explained_table}, $element->{Name})) {
	$self->{explained_field} = $element->{Name};
    } else {
	# start_element now because ValueExplanations::characters may
	# not be called
	$self->SUPER::start_element;
    }
}

sub end_element {
    my ($self, $element) = @_;

    if ($self->current_level eq 'table' && ComposerCat::Database::table_has_explanations ($element->{Name})) {
	$self->{explained_table} = 0;
    } elsif ($self->current_level eq 'field' && ComposerCat::Database::field_has_explanations ($self->{explained_table}, $element->{Name})) {
	$self->{explained_field} = 0;
    }

    # Ensure that ElementStacking's end_element is called *last* so
    # that we are at the right level
    $self->SUPER::end_element($element);
}

sub characters {
    my ($self, $chars) = @_;

    if ($self->{explained_field}) {
	my ($explanation, $location, $position) =
	    ComposerCat::Database::explanations ($self->{explained_table}, $self->{explained_field}, $chars->{Data});

	if (defined $explanation) {
	    # alter the start tag for the field element to include an
	    # @explanation attribute containing the explanation text
	    my $new_field_el = $self->peek_element;
	    _add_attrib($new_field_el, 'explanation', $explanation);
	    $self->replace_element($new_field_el);
	    $self->SUPER::start_element;

	    # create an explanation marker empty element which will
	    # indicate the position of the explanation toggle button
	    my $toggle = _element('explanation-toggle');

	    if ($location eq 'start') {
		$self->SUPER::start_element($toggle);
		$self->SUPER::end_element;

		$self->{Handler}->characters({Data => $chars->{Data}});

	    } elsif ($location eq 'end') {
		$self->{Handler}->characters({Data => $chars->{Data}});

		$self->SUPER::start_element($toggle);
		$self->SUPER::end_element;

	    } elsif ($location eq 'inline') {
		$self->{Handler}->characters({Data => substr($chars->{Data}, 0, $position)});

		$self->SUPER::start_element($toggle);
		$self->SUPER::end_element;

		$self->{Handler}->characters({Data => substr($chars->{Data}, $position + 1)});
	    }
	} else {
	    $self->{Handler}->characters({Data => $chars->{Data}});
	}
    } else {
	$self->{Handler}->characters({Data => $chars->{Data}});
    }
}

sub _element {
    my ($name, $end) = @_;
    return { 
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;
    
    $el->{Attributes}{"{}$name"} = {
	Name => $name,
	LocalName => $name,
	Prefix => "",
	NamespaceURI => "",
	Value => $value,
    };
}

1;
