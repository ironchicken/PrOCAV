#
# ComposerCat
#
# This module provides URL handlers for the public Web user interface
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::PublicUI;

use strict;

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw($view_work $browse_works_by_scored_for $browse_works_by_genre);
}

use Apache2::RequestRec ();
use APR::Table;
use APR::Request::Cookie;
use Apache2::Const -compile => qw(:common);
use XML::Generator::PerlData;
use XML::Generator::DBI;
use XML::Filter::XSLT;
#use XML::Filter::SAX1toSAX2;
#use XML::Handler::HTMLWriter;
use XML::SAX::Writer;
use JSON;
use ComposerCat::Database qw(make_dbh session create_session table_info find_look_up);
use ComposerCat::API qw(request_content_type make_api_function);

my $PROCAV_DOMAIN = "fayrfax.doc.gold.ac.uk";
my $PUBLIC_PATH = "/";
my $TEMPLATES_DIR = "/home/richard/jobs/pocac/procav/web/public/";

our %browse_works_by_scored_for = (
    uri_pattern => qr/^\/works\/?$/,
    required_parameters => [qw(scored_for)],
    optional_parameters => [qw(accept)],
    handle => sub {
	my ($req, $apr_req) = @_;

	} elsif ($content_type eq 'text/xml') {
	    my $writer    = XML::SAX::Writer->new();
	    my $generator = XML::Generator::PerlData->new(Handler => $writer, rootname => 'works');

	
    });

our %browse_works = (
    uri_pattern => qr/^\/works\/?$/,
    optional_parameters => [qw(accept)],
    handle => sub {
	my ($req, $apr_req, $dbh, $url_args) = @_;

    });

our $browse_works_by_scored_for = make_api_function(
    { uri_pattern         => qr/^\/works\/?$/,
      required_parameters => [qw(scored_for)],
      optional_parameters => [qw(accept)],
      accept_types        => ['text/html', 'text/xml', 'application/rdf+xml'],
      generator           => {type => 'proc',
			      proc => sub {
				  my ($req, $apr_req, $dbh, $url_args) = @_;
				  
				  my $st = ComposerCat::Database::table_info('works')->{_list_by_scored_for};
				  $st->execute($apr_req->param("scored_for"));
				  my $works = [];
				  while (my $work = $st->fetchrow_hashref) {
				      push @$works, $work;
				  }
				  
				  return $works;
			      },
			      rootname   => 'works',
			      recordname => 'work'},
      transforms          => {'text/html'           => [$TEMPLATES_DIR . 'browse-works2html.xsl'],
			      'application/rdf+xml' => [$TEMPLATES_DIR . 'browse-works2rdf.xsl']} });

our $browse_works_by_genre = make_api_function(
    { uri_pattern         => qr/^\/works\/?$/,
      required_parameters => [qw(genre)],
      optional_parameters => [qw(accept)],
      accept_types        => ['text/html', 'text/xml', 'application/rdf+xml'],
      generator           => {type => 'proc',
			      proc => sub {
				  my ($req, $apr_req, $dbh, $url_args) = @_;
				  
				  my $st = ComposerCat::Database::table_info('works')->{_list_by_genre};
				  $st->execute($apr_req->param("genre"));
				  my $works = [];
				  while (my $work = $st->fetchrow_hashref) {
				      push @$works, $work;
				  }
				  
				  return $works;
			      },
			      rootname   => 'works',
			      recordname => 'work'},
      transforms          => {'text/html'           => [$TEMPLATES_DIR . 'browse-works2html.xsl'],
			      'application/rdf+xml' => [$TEMPLATES_DIR . 'browse-works2rdf.xsl']} });

our $view_work = make_api_function(
    { uri_pattern => qr/^\/works\/(?<work_id>[0-9]+)\/?$/,
      optional_parameters => [qw(accept)],
      accept_types        => ['text/html', 'text/xml', 'application/rdf+xml'],
      generator           => {type     => 'proc',
			      proc     => sub {
				  my ($req, $apr_req, $dbh, $url_args) = @_;
				  return ComposerCat::Database::complete_work(int($url_args->{work_id}));
			      },
			      rootname => 'work'},
      transforms          => {'text/html'           => [$TEMPLATES_DIR . 'work2html.xsl'],
			      'application/rdf+xml' => [$TEMPLATES_DIR . 'work2rdf.xsl']} });

1;
