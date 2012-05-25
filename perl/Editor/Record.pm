#
# ComposerCat Editor
#
# This module provides a class for creating Tk::Frames for editing
# records
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package Editor::Record;

use strict;

use Tk::Frame;
use base qw(Tk::Derived Tk::Frame);
use Tk::widgets qw(Entry);

Construct Tk::Widget 'Record';

sub ClassInit {
    my ($class, $mw) = @_;

    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my($self, $args) = @_;

    $self->SUPER::Populate($args);
}

1;
