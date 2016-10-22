package Certificate;

use strict;
use warnings;
use Cwd;

BEGIN {unshift @INC, getcwd()}
use parent 'Command';
use Message;


sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    return $self;
}

sub create_key {
    my $self = shift;
    my $cmd = 'openssl genrsa -out server.key 2048';
    $self->exec($cmd);
    if ($self->is_success) {
        $$self{m}->info('server.key created');
    } else {
        $$self{m}->error('failed to create server.key');
        $$self{m}->error($self->out);
    }
}

sub create_extension_req {
    my ($self, $ip) = @_;
    if (! defined $ip) {
        $$self{m}->error('unable to create extension req, no ip specified');
        return 0;
    }
    my $cmd = 'echo -e "basicConstraints=critical,CA:true,pathlen:0\nsubjectAltName=IP:'.$ip.'">extensions.ini';
    $self->exec($cmd);
    if ($self->is_success) {
        $$self{m}->info('extensions.ini created');
    } else {
        $$self{m}->error('failed to create extensions.ini');
        $$self{m}->error($self->out);
    }
}

sub create_csr {
    my $self = shift;
    my $cmd = q!openssl req -new -key server.key -out server.csr -sha256 -subj '/C=CN/ST=Shanghai/L=Shanghai/O=HPE Point/OU=GD Proxy Server'!;
    $self->exec($cmd);
    if ($self->is_success) {
        $$self{m}->info('server.csr created');
    } else {
        $$self{m}->error('failed to create server.csr');
        $$self{m}->error($self->out);
    }
}

sub create_cert {
    my ($self, $ip) = @_;
    my $cmd = 'openssl x509 -req -signkey server.key -days 3650 -in server.csr -out server.crt -extfile extensions.ini'; 
    $self->exec($cmd);
    if (! $self->is_success) {
        $$self{m}->error('failed to create server.crt');
        $$self{m}->error($self->out);
        return 0;
    }

    $$self{m}->info('server.crt created');
    return 1;
}

sub create_key_and_cert {
    my ($self, $ip) = @_;
    if (! defined $ip) {
        $$self{m}->error('unable to create extension req, no ip specified');
        return 0;
    }

    $self->create_key();
    $self->create_csr();
    $self->create_extension_req($ip);
    return $self->create_cert();
}

1;
