#! /usr/bin/env perl

use strict;
use warnings;
use Cwd;
use Getopt::Std;

BEGIN {unshift @INC, getcwd()}

use Message;
use Command;
use NetworkInterface;
use Certificate;
use Docker;


# global variables
my $docker_image = 'ov-proxy';
my $ssl_conf = './template/httpd-ssl.conf.sample';
my $storage_serial_number = './template/storage_systems_serial_number';

my $m = Message->new(level=>'info');
my $r = Command->new(m=>$m);
my $net = NetworkInterface->new(m=>$m);
my $cert = Certificate->new(m=>$m);
my $docker = Docker->new(m=>$m);

sub usage {
    print "usage: $0 options\n";
    print "\t-l list all proxy servers\n";
    print "\t-c create a new prox server\n";
    print "\t-r remove a proxy server by ip\n";
    print "\n";
    exit 1;
}

sub validate_option {
    my $option = shift;
    if (! defined $option->{l} && ! defined $option->{c} && ! defined $option->{r}) {
        usage();
    }
    1;
}

sub create_httpd_ssl_conf {
    # generate unique stings based on proxy server's ip address 
    my $ip = shift;
    my @numbers = split('\.', $ip);
    my @conf_new_lines;
    my $new_conf = "./conf/httpd-ssl.conf.$ip";
    $m->info("creating new httpd ssl conf $new_conf");

    my $server_name = "proxy-$ip";
    my $serial_number = substr(join('', split('\.', $ip)), -6);
    my $dcs_ip_prefix = $numbers[-2].'.'.$numbers[-1];
    my $san_principal_switch = join(':', $serial_number =~ /(\d{2})/g);
    my $volume_wwn = $san_principal_switch;

    push @conf_new_lines, qq(Substitute "s/ci-005056a52e8a/$server_name/");
    push @conf_new_lines, qq(Substitute "s/172.18/$dcs_ip_prefix/");
    push @conf_new_lines, qq(Substitute "s/16.125.106.80/$ip/");
    push @conf_new_lines, qq(Substitute "s/\\"principalSwitch\\":\\".{8}/\\"principalSwitch\\":\\"$san_principal_switch/");
    push @conf_new_lines, qq(Substitute "s/\\"wwn\\":\\"DC:(.{11}):.{8}/\\"wwn\\":\\"DC:\$1:$volume_wwn/");

    # read serial number
    my $id = 1;
    open(my $fh, '<', $storage_serial_number) or die "$!";
    while (<$fh>) {
        chomp;
        my $seq = $id;
        $seq = '0'.$seq if $id < 10;
        push @conf_new_lines, qq(Substitute "s/$_/TX$serial_number$seq/");
        push @conf_new_lines, qq(RewriteRule ^(/rest/storage-systems)/TX$serial_number$seq \$1/$_ [R]); 
        $id += 1;
    }
    close $fh;

    my @ssl_conf_lines;
    open($fh, '<', $ssl_conf) or die "$!"; 
    while (<$fh>) {
        chomp;
        push @ssl_conf_lines, $_;
    }
    close $fh;

    # create new conf file
    open($fh, '>', $new_conf) or die "$1";
    foreach my $line (0..$#ssl_conf_lines) {
        print $fh "$ssl_conf_lines[$line]\n";

        if (defined $ssl_conf_lines[$line+1] && $ssl_conf_lines[$line+1] =~ /<\/VirtualHost>/) {
            # add newlines before end of virtual host
            foreach my $new_line (@conf_new_lines) {
                print $fh "$new_line\n";
            }
        }
    }
    close $fh;
    return $new_conf;
}

# main
my %option;
getopts('lcr:', \%option) or usage();
validate_option(\%option);

# create new proxy server
if (defined $option{c}) {
    if (! $docker->is_image_exist('ov-proxy')) {
        $m->error("docker image $docker_image not exist");
        exit 1;
    }

    # create new virtual network
    #my $ip = '15.114.114.35';
    my $ip = $net->create_virtual_network();
    my $container_name = "$docker_image-$ip";

    # create httpd ssl conf
    my $httpd_ssl_conf = create_httpd_ssl_conf($ip);

    # create server certificate and key
    $cert->create_key_and_cert($ip);

    # create container
    $docker->create_container($docker_image, $ip, $container_name);

    # copy server cert/key and httpd-ssl.conf to container
    $docker->cp_file_to_container('server.key', $container_name, '/usr/local/apache2/conf/');
    $docker->cp_file_to_container('server.crt', $container_name, '/usr/local/apache2/conf/');
    $docker->cp_file_to_container($httpd_ssl_conf, $container_name, '/usr/local/apache2/conf/extra/httpd-ssl.conf');

    # restart container to take new conf effect
    $docker->stop_container($container_name);
    $docker->start_container($container_name);
    
    $docker->get_container_by_name($container_name);
}

# list proxy server
if (defined $option{l}) {
}

# remove proxy server by ip
if (defined $option{r}) {
    usage() unless $option{r};
    # stop container
    # remove container
    # remove virtual network
    $net->remove_virtual_network($option{r});
}
