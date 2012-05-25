#
# ComposerCat Editor
#
# This module provides a class for the main MDI window for the editor
#
# Author: Richard Lewis
# Email: richard.lewis@gold.ac.uk

package Editor::MDI;

use strict;

use Tk;
use Tk::MDI;

sub main {
    my $mw = tkinit;
    my $mdi = $mw->MDI;

    MainLoop;
}

1;
