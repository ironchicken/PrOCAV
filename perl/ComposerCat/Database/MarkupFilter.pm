package ComposerCat::Database::MarkupFilter;

use strict;
use XML::SAX::Base;
use base qw(ComposerCat::Database::ElementStacking); # FIXME Perhaps try extending Text::WikiFormat::SAX instead?

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{syntax} = [
	## level 4 heading
	{pattern  => qr|^(?<!=)={4}([^=]+?)={4}(?!=)$|m,
	 element  => ['h6'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 4; }, sub { 4; }]},

	## level 3 heading
	{pattern  => qr|^(?<!=)={3}([^=]+?)={3}(?!=)$|m,
	 element  => ['h5'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 3; }, sub { 3; }]},
	
	## level 2 heading
	{pattern  => qr|^(?<!=)={2}([^=]+?)={2}(?!=)$|m,
	 element  => ['h4'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 2; }, sub { 2; }]},
	
	## level 1 heading
	{pattern  => qr|^(?<!=)=([^=]+?)=(?!=)$|m,
	 element  => ['h3'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 1; }, sub { 1; }]},
	
	## paragraph
	{pattern  => qr|^([^=].+[^=])$|m,
	 element  => ['p'],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 0; }, sub { 0; }]},
	
	## strong (bold formatted)
	{pattern  => qr|'{3}(.+?)'{3}|m,
	 element  => ['span', {style => sub { 'font-weight:bold'; }}],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 3; }, sub { 3; }]},
	
	# emphasised (italic formatted)
	{pattern  => qr|(?<!')'{2}([^'].+?)'{2}|m,
	 element  => ['span', {style => sub { 'font-style:italic'; }}],
	 get_text => sub { $_[0]; },
	 padding  => [sub { 2; }, sub { 2; }]},
	
	# [URI link text] link
	{pattern  => qr|\[(http:\S+)\s+([^\]]+)\]|m,
	 element  => ['a', {href => sub { $_[0]; }}],
	 get_text => sub { $_[1]; },
	 padding  => [sub { 2 + length $_[0]; }, sub { 1; }]},

	# [table-name.id link text] link
	{pattern  => qr{\[(works|manuscripts|editions|publications|venues|letters|persons)[/.]([0-9]+)\s+([^\]]+)\]}m,
	 element  => ['a', {href => sub { sprintf "/%s/%s", $_[0], $_[1]; }}],
	 get_text => sub { $_[2]; },
	 padding  => [sub { 2 + length $_[0] . $_[1]; }, sub { 1; }]}
	];

    return bless $self, $class;
}

sub start_element {
    my ($self, $element) = @_;
    #my %attrs = %{$element->{Attributes}};

    $self->{parsing_markup} = ComposerCat::Database::allow_markup ($element->{Name});

    $self->SUPER::start_element($element);
}

sub end_element {
    my ($self, $element) = @_;

    $self->{parsing_markup} = 0;

    $self->SUPER::end_element($element);
}

sub characters {
    my ($self, $chars) = @_;

    if ($self->{parsing_markup}) {
	$self->parse_markup($chars->{Data});
    } else {
	$self->SUPER::characters({Data => $chars->{Data}});
    }
}

sub parse_markup {
    my ($self, $chars) = @_;

    # This is a two-pass operation. The first pass identifies
    # occurrences of the syntax regexes and generates a list of
    # 'skip', 'start_element', and 'end_element' events

    my @events = ();
    foreach my $element_type (@{ $self->{syntax} }) {
	while ($chars =~ /$element_type->{pattern}/g) {
	    # FIXME OK, seriously, how do I get a list of the captured
	    # groups when matching with the global modifier?
	    my @capture_groups = ($1, $2, $3, $4, $5, $6, $7, $8, $9);

	    my %attrs = map { $_ => &{ $element_type->{element}->[1]->{$_} }(@capture_groups) } keys %{ $element_type->{element}->[1] };

	    my $element = {match_start => int @-[0],
			   match_end   => int @+[0],
			   skip_before => &{ $element_type->{padding}->[0] }(@capture_groups),
			   skip_after  => &{ $element_type->{padding}->[1] }(@capture_groups),
			   text        => &{ $element_type->{get_text} }(@capture_groups),
			   tag         => $element_type->{element}->[0],
			   attrs       => \%attrs
	    };

	    push @events, ['skip',
			   $element->{match_start},
			   $element->{match_start} + $element->{skip_before}]
			       unless ($element->{skip_before} == 0);

	    push @events, ['start_element',
			   $element->{match_start} + $element->{skip_before},
			   $element];

	    push @events, ['end_element',
			   $element->{match_end} - $element->{skip_after},
			   $element];

	    push @events, ['skip',
			   $element->{match_end} - $element->{skip_after},
			   $element->{match_end}]
			       unless ($element->{skip_after} == 0);
	}
    }

    # The second pass takes each of those events in order of their
    # position in the source characters and emits the required
    # elements and characters.

    # this will be a pointer to the current position in the characters
    # of the field value string
    my $chars_ptr = 0;

    foreach my $event (sort { $a->[1] <=> $b->[1] } @events ) {
	my $type = shift @$event;

	if ($type eq 'skip') {
	    my ($from, $to) = @$event;

	    # consume any characters up to the beginning of the skip
	    $self->SUPER::characters({Data => substr $chars, $chars_ptr, $from - $chars_ptr});

	    # then advance the pointer to the end of the skip
	    $chars_ptr = $to;

	} elsif ($type eq 'start_element') {
	    my ($at, $element) = @$event;

	    # consume any characters up to the beginning of the
	    # element start tag
	    $self->SUPER::characters({Data => substr $chars, $chars_ptr, $at - $chars_ptr});
	    $chars_ptr += ($at - $chars_ptr);

	    # create the element start tag
	    my $el = _element($element->{tag});
	    foreach my $name (keys %{ $element->{attrs} }) {
		_add_attrib($el, $name, $element->{attrs}->{$name});
	    }

	    # and emit it
	    $self->SUPER::start_element($el);

	} elsif ($type eq 'end_element') {
	    my ($at, $element) = @$event;

	    # consume any characters up to the beginning of the
	    # element end tag
	    $self->SUPER::characters({Data => substr $chars, $chars_ptr, $at - $chars_ptr});
	    $chars_ptr += ($at - $chars_ptr);

	    # emit end tag
	    $self->SUPER::end_element;
	} else {
	    die "Invalid event type $type.\n";
	}
    }
}

sub _element {
    my ($name, $end) = @_;
    return { 
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;
    
    $el->{Attributes}{"{}$name"} = {
	Name => $name,
	LocalName => $name,
	Prefix => "",
	NamespaceURI => "",
	Value => $value,
    };
}

1;
