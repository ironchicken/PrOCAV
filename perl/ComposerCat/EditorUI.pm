#
# PrOCAV
#
# This module provides URL handlers for the editors' user interface
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package PrOCAV::EditorUI;

use strict;
use HTML::Template;
use Apache2::RequestRec ();
use APR::Table;
use APR::Request::Cookie;
use Apache2::Const -compile => qw(:common);
use JSON;
use PrOCAV::Database qw(make_dbh session create_session table_info find_look_up);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%home %login %new_session %generate_template %submit_tables %edit_table %table_columns %table_data %table_model %look_up);

my $PROCAV_DOMAIN = "localhost";
my $EDITOR_PATH = "/";
my $TEMPLATES_DIR = "/home/richard/jobs/pocac/procav/web/editor/";

our %home = (
    uri_pattern => qr/^\/?$/,
    required_parameters => [],
    optional_parameters => [qw(failed)],
    handle => sub {
	my ($req, $apr_req) = @_;

	my $in_cookies = $apr_req->jar;

	if (session("editor", $in_cookies->{"login_name"}, $in_cookies->{"procav_editor_sid"})) {
	    $req->headers_out->set(Location => "/new_session");
	    return Apache2::Const::REDIRECT;
	} else {
	    my $template = HTML::Template->new(filename => $TEMPLATES_DIR . "login.tmpl", global_vars => 1);
	    $req->content_type("text/html");
	    if ($apr_req->param("failed")) {
		$template->param(message => $apr_req->param("failed"));
	    }
	    print $template->output();
	    return Apache2::Const::OK;
	}
    });

our %login = (
    uri_pattern => qr/^\/login\/?$/,
    required_parameters => [qw(login_name password)],
    optional_parameters => [qw(login)],
    handle => sub {
	my ($req, $apr_req) = @_;

	my $s = $req->server;

	# FIXME Test for existing session

	my $session_id = create_session("editor", $apr_req->param("login_name"), $apr_req->param("password"));

	if ($session_id) {
	    $s->log_error(sprintf("Created new session for %s with ID %s", $apr_req->param("login_name"), $session_id));

	    my $session_cookie = APR::Request::Cookie->new($apr_req->pool,
							   name    => "procav_editor_sid",
							   value   => $session_id,
							   expires => "+1D",
							   #domain  => $PROCAV_DOMAIN,
							   path    => $EDITOR_PATH);

	    my $login_cookie = APR::Request::Cookie->new($apr_req->pool,
							 name    => "login_name",
							 value   => $apr_req->param("login_name"),
							 expires => "+1D",
							 #domain  => $PROCAV_DOMAIN,
							 path    => $EDITOR_PATH);

	    $req->err_headers_out->add("Set-Cookie", $session_cookie->as_string);
	    $req->err_headers_out->add("Set-Cookie", $login_cookie->as_string);

	    $req->headers_out->set(Location => "/new_session");
	    return Apache2::Const::REDIRECT;
	} else {
	    $s->log_error(sprintf("Failed to creat new session for %s", $apr_req->param("login_name")));

	    $req->headers_out->set(Location => "/?failed=authentication_error");
	    return Apache2::Const::REDIRECT;
	}
    });

our %new_session = (
    uri_pattern => qr/^\/new_session\/?$/,
    handle => sub {
	my ($req, $apr_req) = @_;

	my $template = HTML::Template->new(filename => $TEMPLATES_DIR . "new_session.tmpl", global_vars => 1);

	my $field_order = [@{ table_info('works')->{_field_order} }];
	my $columns = [map { {column => $_}; } @$field_order];

	my $records = [];
	foreach my $work (@{ PrOCAV::Database::list_works() }) {
	    my $fields = [];
	    foreach my $fn (@$field_order) {
		push @$fields, {value => $work->{$fn}};
	    }

	    push @$records, {ID => $work->{ID}, fields => $fields};
	}

	my $param = {tables => [{table_name => 'works',
				 columns => $columns,
				 records => $records}]};

	$template->param($param);

	$req->content_type("text/html");
	print $template->output();
	return Apache2::Const::OK;
    },
    authorisation => "editor");

our %generate_template = (
    uri_pattern => qr/^\/generate_template\/?$/,
    handle => sub {
	my ($req, $apr_req) = @_;
    },
    authorisation => "editor");

our %submit_tables = (
    uri_pattern => qr/^\/submit_tables\/?$/,
    handle => sub {
	my ($req, $apr_req) = @_;
    },
    authorisation => "editor");

our %edit_table_selector = ();

our %edit_table = (
    uri_pattern => qr/^\/edit_table\/?$/,
    required_parameters => [qw(table_name)],
    handle => sub {
	my ($req, $apr_req) = @_;

	my $template = HTML::Template->new(filename => $TEMPLATES_DIR . "edit_table.tmpl", global_vars => 1);

	$req->content_type("text/html");
	print $template->output();
	return Apache2::Const::OK;
    },
    authorisation => "editor");

our %table_columns = (
    uri_pattern => qr/^\/table_columns\/?$/,
    required_parameters => [qw(table_name)],
    handle => sub {
	my ($req, $apr_req) = @_;

	my $columns = table_info($apr_req->param("table_name"))->{_field_order};

	$req->content_type("text/javascript");
	print JSON::encode_json $columns;
	return Apache2::Const::OK;
    },
    authorisation => "editor");

our %table_model = (
    uri_pattern => qr/^\/table_model\/?$/,
    required_parameters => [qw(table_name)],
    handle => sub {
	my ($req, $apr_req) = @_;

	sub column_model {
	    my ($table, $column) = @_;

	    my $column_info = table_info($table)->{$column};
	    my $column_model = {name => $column};
	    my $editoptions = {NullIfEmpty => JSON::true};
	    my $editrules = {};

	    if ($column_info->{access} eq "rw") {
		$column_model->{editable} = JSON::true;
	    } elsif ($column_info->{access} eq "ro") {
		$column_model->{editable} = JSON::false;
		return $column_model;
	    }

	    if ($column_info->{not_null} eq 1) {
		$column_model->{required} = JSON::true;
	    }

	    if ($column_info->{data_type} eq "string") {
		$column_model->{edittype} = "text";
		$editoptions->{maxlength} = $column_info->{width} if (exists $column_info->{width});

	    } elsif ($column_info->{data_type} eq "integer") {
		$column_model->{edittype} = "text";
		$editrules->{integer} = JSON::true;
		if (exists $column_info->{minimum} and exists $column_info->{maximum}) {
		    $editrules->{minValue} = $column_info->{minimum};
		    $editrules->{maxValue} = $column_info->{maximum};
		} elsif (exists $column_info->{minimum}) {
		    $editrules->{minValue} = $column_info->{value};
		} elsif (exists $column_info->{maximum}) {
		    $editrules->{maxValue} = $column_info->{value};
		} elsif (exists $column_info->{foreign_key}) {
		    $column_model->{edittype} = "select";
		    $editoptions->{dataUrl} = "/look_up?look_up_name=" . $column_info->{look_up};
		} else {
		    $editrules->{minValue} = 0;
		}

	    } elsif ($column_info->{data_type} eq "decimal") {
		$column_model->{edittype} = "text";
		$editrules->{number} = JSON::true;

	    } elsif ($column_info->{data_type} eq "boolean") {
		$column_model->{edittype} = "checkbox";
		$editoptions->{value} = "Yes:No";

	    } elsif ($column_info->{data_type} eq "look_up") {
		$column_model->{edittype} = "select";
		$editoptions->{value} = &{ find_look_up($column_info->{look_up}) }();

	    } else {
		if (exists $column_info->{foreign_key}) {
		    $column_model->{edittype} = "select";
		    $editoptions->{dataUrl} = "/look_up?look_up_name=" . $column_info->{foreign_key};
		} else {
		    $column_model->{edittype} = "text";
		}
	    }

	    # # set the column width
	    # if (exists $column_info->{width}) {
	    # 	$sheet->data_validation($row, $col, {validate => 'length',
	    # 					     criteria => '<=',
	    # 					     value    => $column_info->{width}});
	    # }

	    if (keys %$editoptions) { $column_model->{editoptions} = $editoptions; }
	    if (keys %$editrules) { $column_model->{editrules} = $editrules; }

	    return $column_model;
	}

	my @field_order = @{ table_info($apr_req->param("table_name"))->{_field_order} };
	my $columns = [map { column_model($apr_req->param("table_name"), $_); } @field_order];

	$req->content_type("text/javascript");
	print JSON::encode_json $columns;
	return Apache2::Const::OK;
    },
    authorisation => "editor");

our %table_data = (
    uri_pattern => qr/^\/table_data\/?$/,
    required_parameters => [qw(table_name)],
    optional_parameters => [qw(_search nd rows page sidx sord)],
    handle => sub {
	use integer;

	my ($req, $apr_req) = @_;
	my ($table_name, $search, $limit, $page, $order_by, $sort_order) =
	    ($apr_req->param("table_name"), $apr_req->param("_search") || 0, int($apr_req->param("rows")) || 50,
	     int($apr_req->param("page")) || 1, $apr_req->param("sidx"), $apr_req->param("sord"));

	my $field_order = [@{ table_info($table_name)->{_field_order} }];
	my $columns = [map { {column => $_}; } @$field_order];

	my $options = {limit      => $limit,
		       offset     => ($page - 1) * $limit,
		       order_by   => (grep { $_ eq $order_by; } @{ $field_order }) ? $order_by : undef,
		       sort_order => ($order_by && ($sort_order =~ /^(ASC|DESC)$/i)) ? $sort_order : undef};

	my $count = int(PrOCAV::Database::count($table_name));

	my $records = [];
	foreach my $work (@{ PrOCAV::Database::list($table_name, $options) }) {
	    my $fields = [];
	    foreach my $fn (@$field_order) {
		push @$fields, $work->{$fn};
	    }

	    push @$records, {id => $work->{ID}, cell => $fields};
	}

	my $data = {total   => ($count / $limit) + (($count % $limit > 0) ? 1 : 0),
		    page    => $page,
		    records => $count,
		    rows    => $records};

	$req->content_type("text/javascript");
	print JSON::encode_json $data;
	return Apache2::Const::OK;
    },
    authorisation => "editor");

our %look_up = (
    uri_pattern => qr/^\/look_up\/?$/,
    optional_parameters => [qw(table_name look_up_name)],
    handle => sub {
	my ($req, $apr_req) = @_;
	my $dbh = make_dbh;

	$req->content_type("text/html");

	print '<select>';

	if (grep { $_ eq "table_name"; } $apr_req->param) {
	    
	} elsif (grep { $_ eq "look_up_name"; } $apr_req->param) {
	    my $look_up_stmt = &{ find_look_up($apr_req->param("look_up_name")) }($dbh);
	    $look_up_stmt->execute;
	    while (my $item = $look_up_stmt->fetchrow_hashref) {
		print qq|<option value="$item->{value}">$item->{display}</option>|;
	    }
	}

	print '</select>';

	return Apache2::Const::OK;
    },
    authorisation => "editor");
1;
