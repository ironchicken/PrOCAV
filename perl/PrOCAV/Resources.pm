#
# PrOCAV
#
# This module provides methods for retrieving external resources.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

use strict;
use LWP::UserAgent;
use URI;

package Resources;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dbpedia_uri);

sub dbpedia_uri {
    my $topic = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent("PrOCAV/1.0");
    $ua->timeout(1);

    my $dbpedia_uri = URI->new("http://dbpedia.org/resource/$topic");
    my $req = HTTP::Request->new(GET => $dbpedia_uri);
    $req->header("Accept", "application/xml+rdf");
    my $response = $ua->request($req);

    return $dbpedia_uri->uri if ($response->is_success);
}

1;
