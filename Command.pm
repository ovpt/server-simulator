package Command;

use strict;
use warnings;
use Message;


sub new {
    my ($class, %args) = @_;
    my $self = bless({}, $class);
    $$self{m} = defined $args{m} ? $args{m} : Message->new();
    $$self{out} = '';
    $$self{cmd} = '';
    $$self{ret} = 0;
    return $self;
}

sub exec {
    my ($self, $cmd) = @_;
    $$self{m}->info('exec '.$cmd);
    $$self{cmd} = $cmd;
    $$self{out} = `$cmd`;
    $$self{ret} = $?;
    $$self{m}->debug('return value '.$$self{ret});
    $$self{m}->debug('stdout '.$$self{out});
}

sub out {
    my $self = shift;
    return $$self{out};
}

sub ret {
    my $self = shift;
    return $$self{ret};
}

sub is_success {
    my $self = shift;
    return $$self{ret}==0?1:0;
}

sub cmd {
    my $self = shift;
    return $$self{cmd};
}

1;
