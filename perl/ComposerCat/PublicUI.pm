#
# ComposerCat
#
# This module provides URL handlers for the public Web user interface
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::PublicUI;

use strict;
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
use ComposerCat::API qw(request_content_type);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%view_work);

my $PROCAV_DOMAIN = "localhost";
my $PUBLIC_PATH = "/";
my $TEMPLATES_DIR = "/home/richard/jobs/pocac/procav/web/public/";

our %view_work = (
    uri_pattern => qr/^\/works\/(?<work_id>[0-9]+)\/?$/,
    optional_parameters => [qw(accept)],
    handle => sub {
	my ($req, $apr_req, $dbh, $url_args) = @_;

	my $work = ComposerCat::Database::complete_work(int($url_args->{work_id}));

	my $content_type = ComposerCat::API::request_content_type($req, $apr_req, [('text/html', 'text/xml', 'application/xml+rdf')]);

	my $stylesheets = {'text/html'           => $TEMPLATES_DIR . 'work2html.xsl',
			   'application/xml+rdf' => $TEMPLATES_DIR . 'work2rdf.xsl'};

	if (defined $stylesheets->{$content_type}) {
	    my $writer    = XML::SAX::Writer->new();
	    my $xslt_filt = XML::Filter::XSLT->new(Handler => $writer);
	    my $generator = XML::Generator::PerlData->new(Handler => $xslt_filt, rootname => 'work');

	    $xslt_filt->set_stylesheet_uri($stylesheets->{$content_type});
	    $req->content_type($content_type);
	    $generator->parse($work);

	} elsif ($content_type eq 'text/xml') {
	    my $writer    = XML::SAX::Writer->new();
	    my $generator = XML::Generator::PerlData->new(Handler => $writer, rootname => 'work');

	    $req->content_type($content_type);
	    $generator->parse($work);
	}
    });

1;
