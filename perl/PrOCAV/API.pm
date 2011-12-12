#
# PrOCAV
#
# This module exports public API functions which are mapped to
# URLs. FIXME No, it does not.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use Apache2::Request;
#use Apache2::RequestRec ();
#use Apache2::RequestIO ();
use Apache2::Const -compile => qw(:common :log :http);
use Apache2::Cookie;
use Apache2::Log;
use APR::Const -compile => qw(:error SUCCESS);
#use Apache2::Ajax;
use JSON;
use Array::Utils qw(:all);
use PrOCAV::Database qw(session);
use PrOCAV::EditorUI qw(%home %login %new_session %generate_template %submit_tables);

package PrOCAV::API;

sub authorised {
    my ($r, $handler) = @_;

    if (not exists $handler->{authorisation}) { return 1; }

    my %in_cookies = Apache2::Cookie->fetch($r);

    my $sid_name;
    $sid_name = "provac_editor_sid"   if ($handler->{authorisation} eq "editor");
    $sid_name = "provac_consumer_sid" if ($handler->{authorisation} eq "consumer");

    if (not defined $sid_name) {
	die("No matching authorisation scheme: " . $handler->{authorisation} . "\n");
    }

    my $session_id = $in_cookies{$sid_name} && $in_cookies{$sid_name}->value;

    if ($handler->{authorisation} eq "editor") {
	my $login_name = $in_cookies{"login_name"} && $in_cookies{"login_name"}->value;
	return Database::session("editor", $login_name, $session_id);
    }

    if ($handler->{authorisation} eq "consumer") {
	return 0;
    }
}

sub params_present {
    my ($s, $req, $hander) = @_;

    my @supplied = $req->param;
    my @required = @{ $hander->{required_parameters} } or ();
    my @optional = @{ $hander->{optional_parameters} } or ();
    my @permissible = (@required, @optional);

    my @missing = Array::Utils::array_minus(@required, @supplied);
    my @extra = Array::Utils::array_minus(@supplied, @permissible);

    $s->log_error("args: supplied: @supplied; permissible: @permissible; missing: @missing; extra: @extra");

    return (!@missing && !@extra);
}

sub handler {
    my $r = shift;
    my $req = Apache2::Request->new($r);

    my @DISPATCH_TABLE = (
	\%PrOCAV::EditorUI::home,
	\%PrOCAV::EditorUI::login,
	\%PrOCAV::EditorUI::new_session
	);

    my $s = $r->server;

    # iterate over all the URI handlers
    foreach my $h (@DISPATCH_TABLE) {

	$s->log_error(sprintf("Test %s against %s", $r->uri, $h->{uri_pattern}));

	# check if the request path matches this handler's URI pattern
	if ($r->uri =~ $h->{uri_pattern}) {
	    $s->log_error(sprintf("%s matches %s", $r->uri, $h->{uri_pattern}));

	    # check the integrity of the request
	    return Apache2::Const::HTTP_BAD_REQUEST if (not params_present $s, $req, $h);
	    return Apache2::Const::FORBIDDEN if (not authorised $r, $h);

	    # call the handler's handle subroutine
	    return &{$h->{handle}}($r, $req);
	}
    }

    # fall through to returning NOT FOUND if no URI handler matched
    return Apache2::Const::NOT_FOUND;
}

1;
