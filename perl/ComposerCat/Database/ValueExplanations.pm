package ComposerCat::Database::ValueExplanations;

use strict;
use XML::SAX::Base;
use base qw(ComposerCat::Database::ElementStacking);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    return bless $self, $class;
}

sub start_document {
    my ($self, $document) = @_;

    $self->{explained_table} = 0;
    $self->{explained_field} = 0;

    $self->SUPER::start_document($document);
}

sub start_element {
    my ($self, $element) = @_;
    #my %attrs = %{$element->{Attributes}};

    # Ensure that ElementStacking's push_element is called *first* so
    # that we are at the right level. But don't call start_element yet
    # as, if an explanation needs to be included, it will be appended
    # as an attribute to the element
    $self->SUPER::push_element($element);

    if ($self->current_level eq 'table' && ComposerCat::Database::table_has_explanations ($element->{Name})) {
	$self->{explained_table} = $element->{Name};
	# start_element now because ValueExplanations::characters may
	# not be called
	$self->SUPER::start_element;
    } elsif ($self->current_level eq 'field' && ComposerCat::Database::field_has_explanations ($self->{explained_table}, $element->{Name})) {
	$self->{explained_field} = $element->{Name};
    } else {
	# start_element now because ValueExplanations::characters may
	# not be called
	$self->SUPER::start_element;
    }
}

sub end_element {
    my ($self, $element) = @_;

    if ($self->current_level eq 'table' && ComposerCat::Database::table_has_explanations ($element->{Name})) {
	$self->{explained_table} = 0;
    } elsif ($self->current_level eq 'field' && ComposerCat::Database::field_has_explanations ($self->{explained_table}, $element->{Name})) {
	$self->{explained_field} = 0;
    }

    # Ensure that ElementStacking's end_element is called *last* so
    # that we are at the right level
    $self->SUPER::end_element($element);
}

sub characters {
    my ($self, $chars) = @_;

    if ($self->{explained_field}) {
	my ($explanation, $location, $position) =
	    ComposerCat::Database::explanations ($self->{explained_table}, $self->{explained_field}, $chars->{Data});

	if (defined $explanation) {
	    # alter the start tag for the field element to include an
	    # @explanation attribute containing the explanation text
	    my $new_field_el = $self->peek_element;
	    _add_attrib($new_field_el, 'explanation', $explanation);
	    $self->replace_element($new_field_el);
	    $self->SUPER::start_element;

	    # create an explanation marker empty element which will
	    # indicate the position of the explanation toggle button
	    my $toggle = _element('explanation-toggle');

	    if ($location eq 'start') {
		$self->SUPER::start_element($toggle);
		$self->SUPER::end_element;

		$self->{Handler}->characters({Data => $chars->{Data}});

	    } elsif ($location eq 'end') {
		$self->{Handler}->characters({Data => $chars->{Data}});

		$self->SUPER::start_element($toggle);
		$self->SUPER::end_element;

	    } elsif ($location eq 'inline') {
		$self->{Handler}->characters({Data => substr($chars->{Data}, 0, $position)});

		$self->SUPER::start_element($toggle);
		$self->SUPER::end_element;

		$self->{Handler}->characters({Data => substr($chars->{Data}, $position + 1)});
	    }
	} else {
	    $self->{Handler}->characters({Data => $chars->{Data}});
	}
    } else {
	$self->{Handler}->characters({Data => $chars->{Data}});
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
