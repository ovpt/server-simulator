#! /usr/bin/env perl

use strict;
use warnings;
use Cwd;

BEGIN {unshift @INC, getcwd()}

use Message;
use Command;
use NetworkInterface;

my $m = Message->new(level=>'debug');
my $r = Command->new(m=>$m);
my $net = NetworkInterface->new(m=>$m);

$net->get_virtual_networks_config();
$net->create_virtual_network();
$net->get_interface_ip();
$net->remove_virtual_network('');
