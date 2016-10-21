package Docker;


sub new {
    my ($class, %args) = @_;
    my $self = bless({}, $class);
    $$self{m} = defined $args{m} ? $args{m} : Message->new();
    return $self;
}

1;
