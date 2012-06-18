#
# ComposerCat
#
# This module provides methods to render and search digitisations
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package ComposerCat::Digitisations;

use strict;
use File::Temp qw(tempfile);

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(mime_type render);
}

my %RENDERERS = (
    'application/x-lilypond' => \&render_lilypond,
    );

my %MIME_TYPES = (
    'application/x-lilypond' => 'image/png',
    );

sub mime_type {
    my ($media_item) = @_;

    while (my ($in_mime_type, $out_mime_type) = each %MIME_TYPES) {
	if ($media_item->{mime_type} eq $in_mime_type) {
	    return $out_mime_type;
	}
    }
}

sub render {
    my ($media_item, $req) = @_;

    while (my ($mime_type, $renderer) = each %RENDERERS) {
	if ($media_item->{mime_type} eq $mime_type) {
	    return &{ $renderer }($media_item, $req);
	}
    }
}

sub render_lilypond {
    my ($media_item, $req) = @_;

    if (defined $media_item->{data}) {
	my ($tfh, $t) = tempfile;
	my $u;
	my $lilypid = open(LILY, "| lilypond --png -o $t - > /dev/null 2>&1");
	if ($lilypid) {
	    print LILY $media_item->{data};
	    close LILY;
	    waitpid $lilypid, 0;
	    $u = $t . '.png';
	    system "convert $u -trim +repage $u > /dev/null 2>&1";
	    $req->sendfile($u);
	}
	close $tfh;
	unlink $t;
	unlink $u;

	return 1;
    }
}

1;
