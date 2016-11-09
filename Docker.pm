package Docker;

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


sub is_image_exist {
    my ($self, $image) = @_;
    if (! defined $image) {
        $$self{m}->error('no image specified');
        exit 1;
    }
    my $cmd = 'docker images '.$image;
    $self->exec($cmd);
    if (! $self->is_success) {
        $$self{m}->error("image $image not found");
        return 0;
    }

    $$self{m}->info($self->out);
    return 1;
}

sub create_container {
    my ($self, $image, $ip, $name) = @_;
    if (! defined $image) {
        $$self{m}->error('no image specified');
        exit 1;
    }

    if (! defined $ip) {
        $$self{m}->error('no binding host ip specified');
        exit 1;
    }


    $name = $ip unless defined $name;
    my $cmd = "docker run -d -p $ip:443:443 --name $name $image";
    $$self{m}->info("creating container image:$image ip:$ip name:$name");
    $self->exec($cmd);
    if (! $self->is_success) {
        $$self{m}->error('failed to create container');
        return 0;
    } 

    if (! $self->is_container_running($name)) {
        $$self{m}->error("container $name not running");
        return 0;
    }
    
    return $self->get_container_by_name($name);
}

sub get_container_by_name {
    my ($self, $name) = @_;
    if (! defined $name) {
        $$self{m}->error('no container name specified');
        exit 1;
    }
    my $cmd = "docker inspect --type container $name";
    $self->exec($cmd);
    if (! $self->is_success) {
        $$self{m}->error("no such container $name");
        return 0;
    }
    $$self{m}->debug($self->out);
    return $self->out;
}

sub container_exist {
    my ($self, $name) = @_;
    if (! defined $name) {
        $$self{m}->error('no container name specified');
        exit 1;
    }
    my $cmd = "docker inspect --type container $name";
    $self->exec($cmd);
    if (! $self->is_success) {
        $$self{m}->error("no such container $name");
        return 0;
    }
    return 1;
}

sub is_container_running {
    my ($self, $container) = @_;
    if (! defined $container) {
        $$self{m}->error('no container name specified');
        exit 1;
    }

    if (! $self->container_exist($container)) {
        $$self{m}->error("container $container does not exist");
        exit 1;
    }

    my $cmd = qq!docker inspect --type container $container|grep '"Running": true,'!;
    $self->exec($cmd);
    return $self->is_success;
}


sub cp_file_to_container {
    my ($self, $file, $container, $dest_path) = @_;
    if (! defined $file) {
        $$self{m}->error('no file specified');
        exit 1;
    } elsif (! -e $file) {
        $$self{m}->error("file $file does not exist");
        exit 1;
    }

    if (! defined $container) {
        $$self{m}->error('no container specified');
        exit 1;
    }

    if (! defined $dest_path) {
        $$self{m}->error('no dest path specified');
        exit 1;
    }

    if (! $self->is_container_running($container)) {
        $$self{m}->error("container $container is not running");
        exit 1;
    }

    my $cmd = "docker cp $file $container:$dest_path";
    $self->exec($cmd);
    if ($self->is_success) {
        $$self{m}->info("copied $file to $container:$dest_path");
        return 1;
    } else {
        $$self{m}->error("failed to copy $file to $container:$dest_path");
        $$self{m}->error($self->out);
        return 0;
    }
    
}

sub start_container {
    my ($self, $container) = @_;
    if ($self->is_container_running($container)) {
        $$self{m}->info("container $container is already running");
        return 1;
    }

    my $cmd = "docker start $container";
    $$self{m}->info("starting container $container");
    $self->exec($cmd);
    if ($self->is_container_running($container)) {
        $$self{m}->info("container $container is running");
        return 1;
    } else {
        $$self{m}->error("failed to start container $container");
        return 0;
    }
}

sub stop_container {
    my ($self, $container) = @_;
    if (! $self->is_container_running($container)) {
        $$self{m}->info("container $container is already stopped");
        return 1;
    }

    my $cmd = "docker stop $container";
    $$self{m}->info("stopping container $container");
    $self->exec($cmd);
    if (! $self->is_container_running($container)) {
        $$self{m}->info("container $container is stopped");
        return 1;
    } else {
        $$self{m}->error("failed to stop container $container");
        return 0;
    }
}

sub remove_container {
    my ($self, $container) = @_;
    if (! $self->is_container_running($container)) {
        $$self{m}->info("container $container is already stopped");
        return 1;
    }

    my $cmd = "docker rm $container";
    $$self{m}->info("removing container $container");
    $self->exec($cmd);
    if (! $self->container_exist($container)) {
        $$self{m}->info("container $container was removed");
        return 1;
    } else {
        $$self{m}->error("failed to remove container $container");
        return 0;
    }
}


1;
