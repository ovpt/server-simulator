#! /usr/bin/env perl

use strict;
use warnings;
use Cwd;

BEGIN {unshift @INC, getcwd()}

use Message;
use Command;

my $m = Message->new();
my $r = Command->new(m=>$m);

$m->info('hello');
$r->exec('ls');
$m->info($r->out);
$m->info($r->ret);
$m->info($r->cmd);
