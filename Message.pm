package Message;

use strict;
use warnings;


sub new {
    my ($class, %args) = @_;
    my $self = bless({level => defined $args{level}?$args{level}:'info'}, $class);
    return $self;
}

sub p {
    my ($self, $level, $msg) = @_;
    my %identifer = (debug => '*',
                     info => '+',
                     warn => '-',
                     error => '!');
    my @lines = split('\n', $msg);
    foreach (@lines) {
       print "[$identifer{$level}] $_\n";
    }
}

sub debug {
    my ($self, $msg) = @_;
    $self->p('debug', $msg) if $$self{level} =~ /debug/i;
}

sub info {
    my ($self, $msg) = @_;
    $self->p('info', $msg) if $$self{level} =~ /debug|info/i;
}

sub warn {
    my ($self, $msg) = @_;
    $self->p('warn', $msg) if $$self{level} =~ /debug|info|warn/i;
}

sub error {
    my ($self, $msg) = @_;
    $self->p('error', $msg) if $$self{level} =~ /debug|info|warn|error/i;
}

1;

