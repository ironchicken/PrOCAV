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
    our @EXPORT_OK = qw(process_all_pages index_all_pages search_fulltext_index);
}

use ComposerCat::PublicUI qw($view_work);
use ComposerCat::API qw(call_api_function make_paged);

use SWISH::Prog::Indexer;
use SWISH::Prog::Native::Indexer;
use SWISH::Prog::Config;
use SWISH::Prog::Doc;
use SWISH::Prog::Searcher;

our $FULLTEXT_INDEX = '/path/to/composercat/index';

our @page_sources = (
    {path_pattern      => "/works/%d",
     documents_stmt    => q|SELECT ID, uniform_title FROM works WHERE part_of IS NULL ORDER BY ID|,
     path_subs         => sub { ($_[0]->{ID}); },
     make_page_handler => $ComposerCat::PublicUI::view_work,
     handler_args      => sub { {work_id => $_[0]->{ID}}; } }
    );

=method process_all_pages

For each page source in C<@page_sources>, generate all the matching
pages and call the supplied procedure passing, as its argument, a hash
ref containing the path of the page and its text.

=cut

sub process_all_pages {
    my $proc = shift;

    my $dbh = ComposerCat::Database::make_dbh;

    foreach my $source (@page_sources) {
	my $st = $dbh->prepare($source->{documents_stmt});
	$st->execute;

	while (my $doc_details = $st->fetchrow_hashref) {
	    &$proc({
		url     => sprintf($source->{path_pattern}, &{ $source->{path_subs} }($doc_details)),
		content => call_api_function($source->{make_page_handler}, &{ $source->{handler_args} }($doc_details), $dbh)
		   });
	}
    }
}

sub index_all_pages {
    my $config = SWISH::Prog::Config->new(
	DefaultContents     => 'HTML*',
	IndexFile           => $FULLTEXT_INDEX,
	IndexName           => 'PrOCAV',
	PropertyNames       => [qw(DC.title DC.creator DC.date DC.description DC.identifier DC.subject DC.type record-type)],
	MetaNames           => [qw(DC.title DC.creator DC.date DC.description DC.identifier DC.subject DC.type record-type)],
	UndefinedMetaTags   => 'error',
	TranslateCharacters => ':ascii7:');

    my $indexer = SWISH::Prog::Native::Indexer->new(
        invindex    => SWISH::Prog::Native::InvIndex->new(path => $FULLTEXT_INDEX),
        config      => $config,
        count       => 0,
        clobber     => 1,
        flush       => 10000,
        started     => time()
	);

    $indexer->start;

    process_all_pages(sub {
    	my $doc = SWISH::Prog::Doc->new(url => $_[0]->{url}, type => 'text/html', content => $_[0]->{content});
    	$indexer->process($doc);
    		      });
    $indexer->finish;
}

sub search_fulltext_index {
    my ($terms, $start, $limit) = @_;

    # wrap up references to things that look like key signatures in
    # double quotes, making them phrases
    $terms =~ s/([A-G])(#|b| sharp| flat|) (major|minor)/"$1$2 $3"/ig;

    my $searcher = SWISH::Prog::Searcher->new(
	invindex => $FULLTEXT_INDEX,
	max_hits => 500);

    my $found = $searcher->search($terms);
    my $results = [];

    # check integrity of supplied start/limit
    if (defined $start && not defined $limit) { $limit = 10; }
    if (defined $start && $limit < 1) { $limit = 10; }
    if (defined $start && $start < 1) { $start = 1; }
    if (defined $start && $start > $found->hits) { $start = $found->hits; }

    # build an array of results
    while (my $r = $found->next) {
	push @$results, {'dc.title'       => $r->get_property('dc.title'),
			 'dc.creator'     => $r->get_property('dc.creator'),
			 'dc.date'        => $r->get_property('dc.date'),
			 'dc.identifier'  => $r->get_property('dc.identifier'),
			 'dc.description' => $r->get_property('dc.description'),
			 'dc.subject'     => $r->get_property('dc.subject'),
			 'dc.type'        => $r->get_property('dc.type'),
			 record_type      => $r->get_property('record-type'),
			 title            => $r->title,
			 uri              => $r->uri,
			 score            => $r->score};
    }

    return make_paged $results, $start, $limit, 'result', 'hits', $found->hits;
}

1;
