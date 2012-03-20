#
# ComposerCat
#
# This module exports public API functions which are mapped to
# URLs. FIXME No, it does not.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::API;

use strict;

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(request_content_type handler);
}

use APR::Request::Apache2;
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(:common :log :http);
use APR::Request::Cookie;
use Apache2::Log;
use APR::Const -compile => qw(:error SUCCESS);
use HTTP::Headers;
#use Apache2::Ajax;
#use JSON;
use Array::Utils qw(:all);
use ComposerCat::Database qw(session make_dbh);
use ComposerCat::PublicUI qw(%view_work);
use ComposerCat::EditorUI qw(%home %login %new_session %generate_template %submit_tables %edit_table %table_columns %table_data %table_model %look_up);

sub authorised {
    my ($req, $apr_req, $handler) = @_;

    if (not exists $handler->{authorisation}) { return 1; }

    my $s = $req->server;

    my $in_cookies = $apr_req->jar;

    $s->log_error(sprintf("Received cookies: %s", join ", ", keys %$in_cookies));

    my $sid_name;
    $sid_name = "procav_editor_sid"   if ($handler->{authorisation} eq "editor");
    $sid_name = "procav_consumer_sid" if ($handler->{authorisation} eq "consumer");

    $s->log_error(sprintf("Require cookie %s", $sid_name));

    if (not defined $sid_name) {
	die("No matching authorisation scheme: " . $handler->{authorisation} . "\n");
    }

    my $session_id = $in_cookies->{$sid_name};

    $s->log_error(sprintf("Found value for %s: \"%s\"", $sid_name, $session_id));

    if ($handler->{authorisation} eq "editor") {
	my $login_name = $in_cookies->{"login_name"};
	$s->log_error(sprintf("Found value for login_name: \"%s\"", $login_name));
	return session("editor", $login_name, $session_id);
    }

    if ($handler->{authorisation} eq "consumer") {
	return 0;
    }
}

sub params_present {
    my ($req, $apr_req, $handler) = @_;

    my @supplied = $apr_req->param;
    my @required = (exists $handler->{required_parameters}) ? @{ $handler->{required_parameters} } : ();
    my @optional = (exists $handler->{optional_parameters}) ? @{ $handler->{optional_parameters} } : ();
    my @permissible = (@required, @optional);

    my @missing = Array::Utils::array_minus(@required, @supplied);
    my @extra = Array::Utils::array_minus(@supplied, @permissible);

    my $s = $req->server;
    $s->log_error("args: supplied: @supplied; permissible: @permissible; missing: @missing; extra: @extra");

    # there should be no missing parameters, no extra parameters, and
    # no empty required parameters
    my @values = map { $apr_req->param($_); } @required;
    #my $empties = grep { /^(\s*|undefined|null)$/ } @values;
    #$s->log_error("arg values: @values; empties: $empties");
    return (!@missing && !@extra && !grep { /^(\s*|undefined|null)$/ } @values);
}

sub request_content_type {
    my ($req, $apr_req, $acceptable) = @_;

    my $header = HTTP::Headers->new();
    $header->header(Accept => ($apr_req->param('accept')) ? $apr_req->param('accept') : $req->headers_in->get('Accept'));
    my @accepts = $header->header('Accept');

    my @possibles = Array::Utils::intersect(@$acceptable, @accepts);

    $req->server->log_error('Selected Content-Type: ' . @possibles[0]) if (@possibles);
    return @possibles[0] if (@possibles);
    $req->server->log_error('Selected Content-Type: text/html');
    return "text/html";
}

sub handler {
    my $req = shift;
    my $apr_req = APR::Request::Apache2->handle($req);

    my @DISPATCH_TABLE = (
	\%ComposerCat::PublicUI::view_work,
	\%ComposerCat::EditorUI::home,
	\%ComposerCat::EditorUI::login,
	\%ComposerCat::EditorUI::new_session,
	\%ComposerCat::EditorUI::edit_table,
	\%ComposerCat::EditorUI::table_columns,
	\%ComposerCat::EditorUI::table_data,
	\%ComposerCat::EditorUI::table_model,
	\%ComposerCat::EditorUI::look_up
	);

    my $s = $req->server;

    my $dbh = make_dbh;

    # iterate over all the URI handlers
    foreach my $h (@DISPATCH_TABLE) {

	$s->log_error(sprintf("Test %s against %s", $req->uri, $h->{uri_pattern}));

	# check if the request path matches this handler's URI pattern
	if ($req->uri =~ $h->{uri_pattern}) {
	    $s->log_error(sprintf("%s matches %s", $req->uri, $h->{uri_pattern}));

	    # check the integrity of the request
	    return Apache2::Const::HTTP_BAD_REQUEST if (not params_present $req, $apr_req, $h);
	    return Apache2::Const::FORBIDDEN if (not authorised $req, $apr_req, $h);

	    # call the handler's handle subroutine
	    my $response = &{$h->{handle}}($req, $apr_req, $dbh, \%+);

	    # ensure that any database transactions are complete
	    #$dbh->commit;

	    # return whatever the handler's handle subroutine returned
	    return $response;
	}
    }

    # fall through to returning NOT FOUND if no URI handler matched
    return Apache2::Const::NOT_FOUND;
}

1;