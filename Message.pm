package Message;

use strict;
use warnings;


sub new {
    my ($class, %args) = @_;
    my $self = bless({level => 'info'}, $class);
    return $self;
}

sub p {
    my ($self, $level, $msg) = @_;
    my %identifer = (debug => '*',
                     info => '+',
                     warn => '-',
                     error => '!');
    $msg =~ s/\n/ /g;
    print "[$identifer{$level}] $msg\n";
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

