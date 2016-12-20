#! /usr/bin/env perl

use strict;
use warnings;
use Cwd;
use Getopt::Std;

BEGIN {unshift @INC, getcwd()}

use Message;
use Command;
use Certificate;
use Docker;
use HttpdSSLConf;


my $m = Message->new(level=>'info');
my $r = Command->new(m=>$m);
my $cert = Certificate->new(m=>$m);
my $docker = Docker->new(m=>$m);
my $httpd_conf = HttpdSSLConf->new(m=>$m);

sub usage {
    print "\nusage: $0 options\n";
    print "       $0 -t TARGET_SERVER -c CONTAINER_IP\n";
    print "       $0 -i IMAGE_NAME\n";
    print "\n";
    print "\t-t TARGET_SERVER\n";
    print "\t\tThe target server's IP address.\n";
    print "\t-i IMAGE_NAME\n";
    print "\t\tThe docker image.\n";
    print "\t-c CONTAINER_IP\n";
    print "\t\tCreate a new container and forward request to the target server.\n";
    print "\t\tThe CONTAINER_IP is the IP address you want to bind 443 port to.\n";
    print "\n";
    exit 1;
}

sub validate_option {
    my $option = shift;
    if (! defined $option->{t} && ! defined $option->{c} && ! defined $option->{r}) {
        usage();
    }
    1;
}


# main
my %option;
getopts('c:i:r:t:', \%option) or usage();
validate_option(\%option);

# create new proxy server
if (defined $option{c}) {
    if (! defined $option{t}) {
        $m->error("please specify the target server IP address");
        usage();
    }

    if (! defined $option{i}) {
        $m->error("please specify the docker image");
        usage();
    } else {
        if (! $docker->is_image_exist($option{i})) {
            $m->error("docker image $option{i}not exist");
            exit 1;
        }
    }

    # target server appliance IP address
    my $ip = $option{c};
    my $target_srv = $option{t};
    my $container_name = "$option{i}-$ip";

    # create httpd ssl conf
    my $httpd_ssl_conf = $httpd_conf->create_httpd_ssl_conf($ip, $target_srv);

    # create server certificate and key
    $cert->create_key_and_cert($ip);

    # create container
    $docker->create_container($option{i}, $ip, $container_name);

    # copy server cert/key and httpd-ssl.conf to container
    $docker->cp_file_to_container('server.key', $container_name, '/usr/local/apache2/conf/');
    $docker->cp_file_to_container('server.crt', $container_name, '/usr/local/apache2/conf/');
    $docker->cp_file_to_container($httpd_ssl_conf, $container_name, '/usr/local/apache2/conf/extra/httpd-ssl.conf');

    # restart container to take new conf effect
    $docker->stop_container($container_name);
    $docker->start_container($container_name);
    
    $docker->get_container_by_name($container_name);
}


# remove proxy server by ip
if (defined $option{r}) {
    usage() unless $option{r};
    # stop container
    # remove container
}
