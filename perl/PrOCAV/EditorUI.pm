#
# PrOCAV
#
# This module provides URL handlers for the editors' user interface
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use HTML::Template;
use Apache2::RequestRec ();
use APR::Table;
use APR::Request::Cookie;
use Apache2::Const -compile => qw(:common);
use PrOCAV::Database qw(session create_session);

package PrOCAV::EditorUI;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%home %login %new_session %generate_template %submit_tables);

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

	if (Database::session("editor", $in_cookies->{"login_name"}, $in_cookies->{"procav_editor_sid"})) {
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

	my $session_id = Database::create_session("editor", $apr_req->param("login_name"), $apr_req->param("password"));

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

	my $field_order = [@{ Database::table_info('works')->{_field_order} }];
	my $columns = [map { {column => $_}; } @$field_order];

	my $records = [];
	foreach my $work (@{ Database::list_works() }) {
	    my $fields = [];
	    foreach my $fn (@$field_order) {
		push $fields, {value => $work->{$fn}};
	    }

	    push $records, {ID => $work->{ID}, fields => $fields};
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

1;
