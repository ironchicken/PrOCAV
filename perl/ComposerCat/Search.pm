#
# ComposerCat
#
# This module provides interfaces to various search facilities for
# ComposerCat databases, included a fulltext indexer and an advanced
# search.
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::Search;

use strict;

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(process_all_pages);
}

use ComposerCat::PublicUI qw($view_work);
use ComposerCat::API qw(call_api_function);

our @page_sources = (
    {path_pattern      => "/works/%d",
     documents_stmt    => q|SELECT ID, uniform_title FROM works WHERE part_of IS NULL ORDER BY ID|,
     path_subs         => sub { ($_[0]->{ID}); },
     make_page_handler => $ComposerCat::PublicUI::view_work,
     handler_args      => sub { {work_id => $_[0]->{ID}}; } }
    );

sub process_all_pages {
    my $proc = shift;

    my $dbh = ComposerCat::Database::make_dbh;

    foreach my $source (@page_sources) {
	my $st = $dbh->prepare($source->{documents_stmt});
	$st->execute;

	while (my $doc_details = $st->fetchrow_hashref) {
	    my $doc = call_api_function($source->{make_page_handler}, &{ $source->{handler_args} }($doc_details), $dbh);
	    &$proc($doc);
	}
    }
}

1;
