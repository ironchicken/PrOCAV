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
	my ($r, $req) = @_;

	my $in_cookies = $req->jar;

	if (Database::session("editor", $in_cookies->{"login_name"}, $in_cookies->{"procav_editor_sid"})) {
	    $r->headers_out->set(Location => "/new_session");
	    return Apache2::Const::REDIRECT;
	} else {
	    my $template = HTML::Template->new(filename => $TEMPLATES_DIR . "login.tmpl", global_vars => 1);
	    $r->content_type("text/html");
	    if ($req->param("failed")) {
		$template->param(message => $req->param("failed"));
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
	my ($r, $req) = @_;

	my $s = $r->server;

	my $session_id = Database::create_session("editor", $req->param("login_name"), $req->param("password"));

	if ($session_id) {
	    $s->log_error(sprintf("Created new session for %s with ID %s", $req->param("login_name"), $session_id));

	    my $session_cookie = APR::Request::Cookie->new($req->pool,
							   name    => "provac_editor_sid",
							   value   => $session_id,
							   expires => "+1D",
							   domain  => $PROCAV_DOMAIN,
							   path    => $EDITOR_PATH,
							   secure  => 1);

	    my $login_cookie = APR::Request::Cookie->new($req->pool,
							 name    => "login_name",
							 value   => $req->param("login_name"),
							 expires => "+1D",
							 domain  => $PROCAV_DOMAIN,
							 path    => $EDITOR_PATH,
							 secure  => 1);

	    $r->err_headers_out->add("Set-Cookie", $session_cookie->as_string);
	    $r->err_headers_out->add("Set-Cookie", $login_cookie->as_string);

	    $r->headers_out->set(Location => "/new_session");
	    return Apache2::Const::REDIRECT;
	} else {
	    $s->log_error(sprintf("Failed to creat new session for %s", $req->param("login_name")));

	    $r->headers_out->set(Location => "/?failed=authentication_error");
	    return Apache2::Const::REDIRECT;
	}
    });

our %new_session = (
    uri_pattern => qr/^\/new_session\/?$/,
    handle => sub {
	my ($r, $req) = @_;
    },
    authorisation => "editor");

our %generate_template = (
    uri_pattern => qr/^\/generate_template\/?$/,
    handle => sub {
	my ($r, $req) = @_;
    },
    authorisation => "editor");

our %submit_tables = (
    uri_pattern => qr/^\/submit_tables\/?$/,
    handle => sub {
	my ($r, $req) = @_;
    },
    authorisation => "editor");

1;
