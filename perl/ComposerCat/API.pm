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
    our @EXPORT_OK = qw(request_content_type make_api_function call_api_function make_paged handler init);
}

use DateTime;
use Apache2::RequestRec ();
use APR::Request::Apache2;
use Apache2::Const -compile => qw(:common :log :http);
use APR::Table;
use APR::Request::Cookie;
use CGI::Cookie;
use Apache2::Log;
use APR::Const -compile => qw(:error SUCCESS);
use HTTP::Headers;
use Array::Utils qw(:all);
use XML::SAX::Machines qw(Pipeline);
use XML::Generator::PerlData;
use XML::Filter::BufferText;
use XML::Filter::XSLT;
use XML::SAX::Writer;
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

    $s->log_error(sprintf("Found value for %s: \"%s\"", $sid_name, $session_id));

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

sub cookie {
    my ($name, $req, $apr_req) = @_;

    # the cookie is either in the request (if the client sent a
    # cookie) or it's in the response (if a new cookie is being sent)

    if (defined $apr_req->jar) {
	$apr_req->jar->{$name};
    } else {
	my $cookies_out = CGI::Cookie->parse($req->err_headers_out->get('Set-Cookie'));
	$cookies_out->{$name};
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
	optional_parameters => $options->{optional_parameters} || [],
	error_code          => $options->{error_code} || Apache2::Const::HTTP_OK};

    $func->{handle} = $options->{handle} || sub {
	my ($req, $apr_req, $dbh, $url_args, $dest) = @_;

	$dest = $dest || \*STDOUT;

	# find out what content type is requested
	my $content_type = request_content_type($req, $apr_req, (defined $options->{accept_types}) ?
						$options->{accept_types} :
						['text/html', 'text/xml']);

	binmode($dest, ':utf8:');

	# construct a SAX processing pipeline
	my @p = (XML::Filter::BufferText->new,
		 ComposerCat::Database::MarkupFilter->new,
		 ComposerCat::Database::ValueAnnotations->new);
	
	if (defined $options->{transforms} && defined $options->{transforms}->{$content_type}) {
	    push @p, map { XML::Filter::XSLT->new(Source => {SystemId => $_}); } @{ $options->{transforms}->{$content_type} };
	}

	push @p, XML::SAX::Writer->new(Output         => $dest,
				       Escape         => {'&' => '&amp;',
							  '<' => '&lt;',
							  '>' => '&gt;'},
				       QuoteCharacter => '"',
				       EncodeFrom     => 'UTF-8',
				       EncodeTo       => 'UTF-8');

	my $pipeline = Pipeline(@p);

	# begin the response
	$req->content_type(($content_type eq 'text/html') ? 'text/html; charset=utf-8' : $content_type);

	print $dest '<?xml version="1.0" encoding="utf-8" ?>';
	print $dest '<!DOCTYPE html>' if ($content_type eq 'text/html');

	# construct an XML generator and execute the SAX pipeline
	my $generator;

	if ($options->{generator}->{type} eq 'proc') {
	    # add some request information to the response data
	    my @params = $apr_req->param;

	    my $response = {request => {retrieved  => sprintf("%s", DateTime->now(time_zone => 'local')),
	    				path       => $req->uri,
	    				params     => [map { {name => $_, value => $apr_req->param($_) }; } @params],
	    				session_id => cookie 'composercat_public_sid', $req, $apr_req}};

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
	return $func->{error_code};
    };

    return $func;
}

sub call_api_function {
    my ($handler, $url_args, $dbh) = @_;
    $dbh = make_dbh if (not defined $dbh);

    # Callees to this subroutine should arrange to import the
    # Test::Mock::Apache2 module to replace these two classes with
    # dummy versions that will work outside of the Apache environment
    my $req = Apache2::RequestUtil->request();
    my $apr_req = APR::Request::Apache2->handle($req);

    # create a filehandle which writes to a scalar as a place to dump
    # the output from the handler procedure
    my $output;
    open my $fh, ">", \$output;

    # call the handler procedure
    &{ $handler->{handle} }($req, $apr_req, $dbh, $url_args, $fh);

    return $output;
}

sub make_paged {
    my ($records, $start, $limit, $record_name, $total_name, $total) = @_;
    $record_name ||= 'record';
    $total_name  ||= 'total';
    $total       ||= scalar @{ $records };

    my $this_page = []; my $n = 0; my $count = 0;
    foreach my $r (@$records) {
	$n++;
	next if (defined $start && $n < $start);
	$r->{n} = $n;
	push @$this_page, $r;
	$count++;
	last if (defined $limit && $count == $limit);
    }

    return {$total_name  => $total,
	    start        => $start,
	    # FIXME prev and next should be part of the more general
	    # session-based index mechanism; these are a temporary
	    # kludge
	    prev         => &{ sub { if (defined $start && defined $limit) { if ($start == 1) { return undef; } else { return ($start - $limit > 1) ? $start - $limit : 1; } } } }(),
	    'next'       => &{ sub { if (defined $start && defined $limit) { return ($start + $limit > $total) ? undef : $start + $limit; } } }(),

	    limit        => $limit,
	    count        => $count,
	    $record_name => $this_page};
}

our @DISPATCH_TABLE = ();

sub init {
    use ComposerCat::PublicUI qw($home $browse $about $view_work $browse_works_by_scored_for $browse_works
                                 $browse_works_by_genre $browse_works_by_title $fulltext_search
                                 $bad_arguments $not_found);

    use ComposerCat::EditorUI qw(%home %login %new_session %generate_template %submit_tables
                                 %edit_table %table_columns %table_data %table_model %look_up);

    @DISPATCH_TABLE = (
    	$ComposerCat::PublicUI::home,
    	$ComposerCat::PublicUI::browse,
    	$ComposerCat::PublicUI::about,
    	$ComposerCat::PublicUI::view_work,
    	$ComposerCat::PublicUI::browse_works,
    	$ComposerCat::PublicUI::browse_works_by_scored_for,
	$ComposerCat::PublicUI::browse_works_by_genre,
	$ComposerCat::PublicUI::browse_works_by_title,
	$ComposerCat::PublicUI::fulltext_search,
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

    # iterate over all the URI handlers, storing any error encountered
    # in $error
    my @error;
    foreach my $h (@DISPATCH_TABLE) {

	$s->log_error(sprintf("Test %s against %s", $req->uri, $h->{uri_pattern}));

	# check if the request path matches this handler's URI pattern
	if ($req->uri =~ $h->{uri_pattern}) {
	    $s->log_error(sprintf("%s matches %s", $req->uri, $h->{uri_pattern}));

	    # check the integrity of the request

	    #return Apache2::Const::HTTP_BAD_REQUEST if (not params_present $req, $apr_req, $h);
	    if (not params_present $req, $apr_req, $h) {
		@error = ($ComposerCat::PublicUI::bad_arguments, $h, \%+);
		next;
	    }

	    return Apache2::Const::FORBIDDEN if (not authorised $req, $apr_req, $h);

	    # retrieve or create session
	    open_session $req, $apr_req, $h if (defined $h->{require_session});

	    # call the handler's handle subroutine
	    my $status = &{$h->{handle}}($req, $apr_req, $dbh, \%+);

	    # ensure that any database transactions are complete
	    #$dbh->commit;

	    # return whatever the handler's handle subroutine returned
	    $req->status($status);
	    return Apache2::Const::OK;
	}
    }

    if (@error) {
	my ($error, $failed_handler, $failed_args) = @error;
	my $error_response = &{ $error->{handle} }($req, $apr_req, $dbh, $failed_args);
	$req->status($error->{error_code});
	return Apache2::Const::OK;
    } else {
	# fall through to returning NOT FOUND if no URI handler
	# matched and no error was signaled while searching the
	# DISPATCH_TABLE
	$s->log_error("Fell through to NOT_FOUND for: " . $req->uri);
	my $error_response = &{ $ComposerCat::PublicUI::not_found->{handle} }($req, $apr_req, $dbh);
	$req->status($ComposerCat::PublicUI::not_found->{error_code});
	return Apache2::Const::OK;
    }
}

1;
