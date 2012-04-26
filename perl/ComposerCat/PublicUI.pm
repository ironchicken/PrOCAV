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
    our @EXPORT_OK = qw($home $browse $about $view_work $browse_works_by_scored_for
                        $browse_works_by_genre $fulltext_search);
}

use Apache2::RequestRec ();
use APR::Table;
use APR::Request::Cookie;
use Apache2::Const -compile => qw(:common);
use XML::Generator::PerlData;
use XML::Filter::XSLT;
#use XML::Filter::SAX1toSAX2;
#use XML::Handler::HTMLWriter;
use XML::SAX::Writer;
use JSON;
use ComposerCat::Database qw(make_dbh session create_session table_info find_look_up);
use ComposerCat::API qw(request_content_type make_api_function);
use ComposerCat::Search qw(search_fulltext_index);

my $PROCAV_DOMAIN = "localhost";
my $PUBLIC_PATH = "/";
my $DOCUMENTS_DIR = "/home/richard/jobs/pocac/procav/web/public/";
my $TEMPLATES_DIR = "/home/richard/jobs/pocac/procav/web/public/";

our $home = make_api_function(
    { uri_pattern         => qr|^/?$|,
      require_session     => 'public',
      required_parameters => [],
      optional_parameters => [],
      accept_types        => ['text/html'],
      generator           => {type => 'file', path => $DOCUMENTS_DIR . 'home.xml'},
      transforms          => {'text/html' => [$TEMPLATES_DIR . 'document2html.xsl']} });

our $browse = make_api_function(
    { uri_pattern         => qr|^/browse?$|,
      require_session     => 'public',
      required_parameters => [],
      optional_parameters => [],
      accept_types        => ['text/html'],
      generator           => {type => 'file', path => $DOCUMENTS_DIR . 'browse-selection.xml'},
      transforms          => {'text/html' => [$TEMPLATES_DIR . 'document2html.xsl']} });

our $about = make_api_function(
    { uri_pattern         => qr|^/about?$|,
      require_session     => 'public',
      required_parameters => [],
      optional_parameters => [],
      accept_types        => ['text/html'],
      generator           => {type => 'file', path => $DOCUMENTS_DIR . 'about.xml'},
      transforms          => {'text/html' => [$TEMPLATES_DIR . 'document2html.xsl']} });

our $browse_works_by_scored_for = make_api_function(
    { uri_pattern         => qr|^/works/?$|,
      require_session     => 'public',
      required_parameters => [qw(scored_for)],
      optional_parameters => [qw(cmp accept submit)],
      accept_types        => ['text/html', 'text/xml', 'application/rdf+xml'],
      generator           => {type => 'proc',
			      proc => sub {
				  my ($req, $apr_req, $dbh, $url_args) = @_;

				  # split the scored_for argument into
				  # a list of strings
				  my @instruments = split /\W+/, $apr_req->param('scored_for');

				  # select a statement to use
				  # depending on the cardinality of
				  # the scored_for list and value of
				  # the 'cmp' argument
				  my $st_name = ($apr_req->param('cmp') eq 'only' || not defined $apr_req->param('cmp')) ?
				      '_list_by_scored_for' :
				      '_list_by_scored_for_' . sub { my $cmp = $apr_req->param('cmp'); $cmp =~ s/-/_/; $cmp; }->();

				  my $st = ComposerCat::Database::table_info('works')->{$st_name} ||
				      ComposerCat::Database::table_info('works')->{_list_by_scored_for};

				  # execute the selected statement
				  # with an appropriately formatted
				  # argument
				  if ($st_name eq '_list_by_scored_for') {
				      $st->execute($apr_req->param('scored_for'));
				  } else {
				      if ($apr_req->param('cmp') eq 'any') {
					  $st->execute('(' . join('|', @instruments) . ')');
				      } elsif ($apr_req->param('cmp') eq 'all' || $apr_req->param('cmp') eq 'not-all') {
					  $st = $st->(@instruments);
					  $st->execute(@instruments);
				      }
				  }

				  # construct an array ref of the
				  # results
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
    { uri_pattern         => qr|^/works/?$|,
      require_session     => 'public',
      required_parameters => [qw(genre)],
      optional_parameters => [qw(accept submit)],
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
    { uri_pattern         => qr|^/works/(?<work_id>[0-9]+)/?$|,
      require_session     => 'public',
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

our %view_period = ();

our $fulltext_search = make_api_function(
    { uri_pattern         => qr|^/search$|,
      require_session     => 'public',
      required_parameters => [qw(terms)],
      optional_parameters => [qw(accept start limit)],
      accept_types        => ['text/html', 'text/xml'],
      generator           => {type => 'proc',
			      proc => sub {
				  my ($req, $apr_req, $dbh, $url_args) = @_;
				  return ComposerCat::Search::search_fulltext_index($apr_req->param('terms'),
										    $apr_req->param('start'),
										    $apr_req->param('limit'));
			      },
			      rootname   => 'results',
			      recordname => 'result'},
      transforms          => {'text/html' => [$TEMPLATES_DIR . 'fulltext-results2html.xsl']} });

1;
