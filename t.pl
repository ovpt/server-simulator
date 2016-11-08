#! /usr/bin/env perl

use strict;
use warnings;
use Cwd;

BEGIN {unshift @INC, getcwd()}

use Message;
use Command;
use NetworkInterface;
use Certificate;
use Docker;

#my $m = Message->new(level=>'debug');
my $m = Message->new(level=>'info');
my $r = Command->new(m=>$m);
my $net = NetworkInterface->new(m=>$m);
my $cert = Certificate->new(m=>$m);
my $docker = Docker->new(m=>$m);

#$net->get_virtual_networks_config();
$net->create_virtual_network();
$net->get_interface_ip();
#$net->remove_virtual_network('');

#$cert->create_key_and_cert('15.114.114.114');

#$docker->is_image_exist('ov-proxy');
#$docker->get_container_by_name('ov-proxy');
#$docker->cp_file_to_container('server.key', 'httpd-t', '/usr/local/apache2/conf/');
#$docker->start_container('httpd-t');
#$docker->stop_container('httpd-t');
#$docker->start_container('httpd-t');
#$docker->stop_container('httpd-t-no');
