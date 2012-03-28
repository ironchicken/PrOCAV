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
    our @EXPORT_OK = qw(request_content_type make_api_function handler init);
}

use DateTime;
use APR::Request::Apache2;
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(:common :log :http);
use APR::Request::Cookie;
use CGI::Cookie;
use Apache2::Log;
use APR::Const -compile => qw(:error SUCCESS);
use HTTP::Headers;
#use Apache2::Ajax;
#use JSON;
use Array::Utils qw(:all);
use XML::SAX::Machines qw(Pipeline);
use XML::Filter::XSLT;
use ComposerCat::Database qw(make_dbh session create_session);

sub authorised {
    my ($req, $apr_req, $handler) = @_;

    if (not exists $handler->{authorisation}) { return 1; }

    my $s = $req->server;

    my $in_cookies = $apr_req->jar;

    $s->log_error(sprintf("Received cookies: %s", join ", ", keys %$in_cookies));

    my $sid_name;
    $sid_name = "composercat_editor_sid"   if ($handler->{authorisation} eq "editor");
    $sid_name = "composercat_consumer_sid" if ($handler->{authorisation} eq "consumer");

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

sub open_session {
    my ($req, $apr_req, $handler) = @_;

    my $s = $req->server;

    my $in_cookies = $apr_req->jar;

    $s->log_error(sprintf("Received cookies: %s", join ", ", keys %$in_cookies));

    my $sid_name;
    $sid_name = "composercat_public_sid" if ($handler->{require_session} eq "public");

    $s->log_error(sprintf("Require cookie %s", $sid_name));

    if (not defined $sid_name) {
	die("No matching session class: " . $handler->{require_session} . "\n");
    }

    my $session_id = $in_cookies->{$sid_name};

    $s->log_error(sprintf("Found value for : \"%s\"", $sid_name, $session_id));

    if (not session $handler->{require_session}, 0, $session_id) {
	$session_id = create_session $handler->{require_session};

	$s->log_error(sprintf("Created new public session with ID %s", $session_id));

	my $session_cookie = APR::Request::Cookie->new($apr_req->pool,
						       name    => $sid_name,
						       value   => $session_id,
						       expires => "+10Y",
						       path    => '/');

	$req->err_headers_out->add("Set-Cookie", $session_cookie->as_string);
    }
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

sub make_api_function {
    my $options = shift;

    my $func = {
	uri_pattern         => $options->{uri_pattern},
	require_session     => $options->{require_session},
	required_parameters => $options->{required_parameters} || [],
	optional_parameters => $options->{optional_parameters} || []};

    $func->{handle} = $options->{handle} || sub {
	my ($req, $apr_req, $dbh, $url_args) = @_;
	
	my $content_type = request_content_type($req, $apr_req, (defined $options->{accept_types}) ?
						$options->{accept_types} :
						['text/html', 'text/xml']);

	my $pipeline;

	if (defined $options->{transforms} && defined $options->{transforms}->{$content_type}) {
	    my @p = map { XML::Filter::XSLT->new(Source => {SystemId => $_}); } @{ $options->{transforms}->{$content_type} };
	    push @p, XML::SAX::Writer->new( Output => \*STDOUT );
	    $pipeline = Pipeline(@p);
	} else {
	    $req->server->log_error("Creating pipeline with SAX::Writer");
	    $pipeline = XML::SAX::Writer->new( Output => \*STDOUT );
	}

	$req->content_type($content_type);
	print '<?xml version="1.0" encoding="utf-8" ?>';
	print '<!DOCTYPE html>' if ($content_type eq 'text/html');

	my $generator;

	if ($options->{generator}->{type} eq 'proc') {
	    # add some request information to the response data
	    my @params = $apr_req->param;

	    # session ID is either is the request (if the client sent
	    # a cookie) or it's in the response (if a new cookie is
	    # being sent)
	    my $session_id;
	    if (defined $apr_req->jar) {
		$session_id = $apr_req->jar->{composercat_public_sid};
	    } else {
	    	my $cookies_out = CGI::Cookie->parse($req->err_headers_out->get('Set-Cookie'));
	    	$session_id = $cookies_out->{composercat_public_sid};
	    }

	    my $response = {request => {retrieved  => sprintf("%s", DateTime->now(time_zone => 'local')),
	    				path       => $req->uri,
	    				params     => [map { {name => $_, value => $apr_req->param($_) }; } @params],
	    				session_id => $session_id}};

	    # execute the handler procedure
	    my $data = &{ $options->{generator}->{proc} }($req, $apr_req, $dbh, $url_args);

	    # set up an XML generator
	    $generator = XML::Generator::PerlData->new(Handler => $pipeline, rootname => 'response');
	    if (ref $data eq "ARRAY") {
		# if the handler procedure returned an array, then add
		# it to the response data using the supplied
		# 'recordname' as a key; this will ensure that the
		# multiple items in the array are each contained in
		# elements whose tag name is the value of 'recordname'
		$response->{content} = {$options->{generator}->{recordname} => $data};
	    } else {
		# otherwise, add the handler return value to the
		# response data using the supplied 'rootname' as a key
		$response->{content} = {$options->{generator}->{rootname} => $data};
	    }
	    $generator->parse($response);
	} elsif ($options->{generator}->{type} eq 'file') {
	    $pipeline->parse_file($options->{generator}->{path});
	}
	return Apache2::Const::OK;
    };

    return $func;
}

our @DISPATCH_TABLE = ();

sub init {
    use ComposerCat::PublicUI qw($home $view_work $browse_works_by_scored_for $browse_works_by_genre);
    use ComposerCat::EditorUI qw(%home %login %new_session %generate_template %submit_tables %edit_table %table_columns %table_data %table_model %look_up);

    @DISPATCH_TABLE = (
    	$ComposerCat::PublicUI::home,
    	$ComposerCat::PublicUI::view_work,
    	$ComposerCat::PublicUI::browse_works_by_scored_for,
	$ComposerCat::PublicUI::browse_works_by_genre,
    	\%ComposerCat::EditorUI::home,
    	\%ComposerCat::EditorUI::login,
    	\%ComposerCat::EditorUI::new_session,
    	\%ComposerCat::EditorUI::edit_table,
    	\%ComposerCat::EditorUI::table_columns,
    	\%ComposerCat::EditorUI::table_data,
    	\%ComposerCat::EditorUI::table_model,
    	\%ComposerCat::EditorUI::look_up
    	);
}

sub handler {
    my $req = shift;
    my $apr_req = APR::Request::Apache2->handle($req);

    my $s = $req->server;

    my $dbh = make_dbh;

    # iterate over all the URI handlers
    foreach my $h (@DISPATCH_TABLE) {

	$s->log_error(sprintf("Test %s against %s", $req->uri, $h->{uri_pattern}));

	# check if the request path matches this handler's URI pattern
	if ($req->uri =~ $h->{uri_pattern}) {
	    $s->log_error(sprintf("%s matches %s", $req->uri, $h->{uri_pattern}));

	    # check the integrity of the request

	    #return Apache2::Const::HTTP_BAD_REQUEST if (not params_present $req, $apr_req, $h);

	    # FIXME Now incorrect parameters will result in 404, not
	    # 400. But handlers with identical URI patterns will have
	    # a chance to be matched. Consider saving some state
	    # information when a params_present test fails.
	    next if (not params_present $req, $apr_req, $h);
	    return Apache2::Const::FORBIDDEN if (not authorised $req, $apr_req, $h);

	    # retrieve or create session
	    open_session $req, $apr_req, $h if (defined $h->{require_session});

	    # call the handler's handle subroutine
	    my $response = &{$h->{handle}}($req, $apr_req, $dbh, \%+);

	    # ensure that any database transactions are complete
	    #$dbh->commit;

	    # return whatever the handler's handle subroutine returned
	    return $response;
	}
    }

    # fall through to returning NOT FOUND if no URI handler matched
    $s->log_error("Fell through to NOT_FOUND");
    return Apache2::Const::NOT_FOUND;
}

1;
