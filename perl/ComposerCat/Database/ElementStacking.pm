package ComposerCat::Database::ElementStacking;

use strict;
use XML::SAX::Base;
use base qw(XML::SAX::Base); # FIXME Perhaps try extending Text::WikiFormat::SAX instead?

sub new {
    my $class = shift;
    my %options = @_;

    $options{level} = ['document', 'response', 'content', 'record', 'table', 'field'];

    return bless \%options, $class;
}

sub start_document {
    my ($self, $document) = @_;

    $self->{element_stack} = [];

    $self->SUPER::start_document($document);
}

sub current_level {
    my ($self) = @_;

    return $self->{level}->[scalar @{ $self->{element_stack} }];
}

sub push_element {
    my ($self, $element) = @_;

    push @{ $self->{element_stack} }, $element;

    return $element;
}

sub replace_element {
    my ($self, $new_element) = @_;

    my $replaced_element = pop @{ $self->{element_stack} };

    return $self->push_element($new_element);
}

sub start_element {
    my ($self, $element) = @_;

    if (defined $element) {
	$self->push_element($element);
    }

    $self->SUPER::start_element($self->{element_stack}->[-1]);
}

sub peek_element {
    $_[0]->{element_stack}->[-1];
}

sub pop_element {
    return pop @{ $_[0]->{element_stack} };
}

sub end_element {
    my ($self, $element) = @_;

    my $leaving = $self->pop_element;

    $self->SUPER::end_element($element || _element($leaving->{Name}, 1));
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
