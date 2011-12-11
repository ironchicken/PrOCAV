#
# PrOCAV
#
# This module provides URL handlers for the editors' user interface
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use HTML::Template;
use Apache2::Cookie;
use Apache2::Const -compile => qw(:common);
use PrOCAV::Database qw(create_session);

package PrOCAV::EditorUI;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%login %new_session %generate_template %submit_tables);

my $PROCAV_DOMAIN = "localhost";
my $EDITOR_PATH = "/";
my $TEMPLATES_DIR = "../../web/editor";

our %login = (
    uri_pattern => qr/^\/login\/?$/,
    required_parameters => [qw(login_name password)],
    handle => sub {
	my ($r, $req) = @_;

	my $session_id = Database::create_session($req->param("login_name"), $req->param("password"));

	if ($session_id) {
	    my $session_cookie = Apache2::Cookie->new($r,
						      name    => "provac_editor_sid",
						      value   => $session_id,
						      expires => "+1D",
						      domain  => $PROCAV_DOMAIN,
						      path    => $EDITOR_PATH,
						      secure  => 1);
	    $session_cookie->bake;
	    $r->headers_out->set(Location => "/new_session");
	    return Apache2::Const::REDIRECT;
	} else {
	    $r->headers_out->set(Location => "/login?failed=authentication_error");
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
