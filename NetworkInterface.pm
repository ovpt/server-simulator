package NetworkInterface;

use strict;
use warnings;
use Cwd;
use Data::Dumper;

BEGIN {unshift @INC, getcwd()}

use parent 'Command';


sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $$self{interface} = '';
    $$self{ifcfgs} = ();
    $$self{cfg_path} = '/etc/sysconfig/network-scripts/';
    return $self;
}

sub interface {
    my $self = shift;
    if (! $$self{interface}) {
        my $cmd = q!ls -l /sys/class/net|sed -n -e 's|.* \(.*\) -> .*/devices/pci.*|\1|gp'!;
        $self->exec($cmd);
        $$self{interface} = $self->out;
        chomp($$self{interface});
    }
    return $$self{interface};
}

sub get_virtual_networks_config {
    my $self = shift;
    my $abs_path = $$self{cfg_path};
    my $cmd = 'ls '.$abs_path.'ifcfg-'.$self->interface.':*';
    my @ifcfgs;
    $self->exec($cmd);
    if ($self->out) {
        @ifcfgs = split('\s+', $self->out);
    }
    foreach my $cfg (@ifcfgs) {
        my %virt_net = (device=>'',abs_path=>$cfg, obtained_ip=>'');
        my $seq = '';
        $$self{m}->info('reading configuration '.$cfg);
        open (my $fh, '<', $cfg);
        while (<$fh>) {
            chomp;
            ($virt_net{device}, $seq) = ($1, $3) if /^DEVICE=((\w+):(\d+))$/;
            $virt_net{obtained_ip} = $1 if /^#obtained_ip=((\d+\.){3}\d+)$/;
        }
        close $fh;
        $virt_net{abs_path} = $cfg;
        $$self{m}->debug('device '.$virt_net{device});
        $$self{m}->debug('sequence '.$seq);

        if (! $virt_net{obtained_ip}) {
            $$self{m}->warn('no #obtained_ip found');
        } else {
            $$self{m}->debug('obtained_ip '.$virt_net{obtained_ip});
        }

        if (! defined $$self{ifcfgs}->{$seq}) {
            $$self{ifcfgs}->{$seq} = \%virt_net;
        } else {
            $$self{m}->error('duplicate virtual network sequence '.$seq);
        }
    }
    return $$self{ifcfgs};
}

sub create_virtual_network {
    my $self = shift;
    $self->get_virtual_networks_config() if ! $$self{ifcfgs};
    my $next_seq = 1;
    if ($$self{ifcfgs}) {
        my @sequences = sort {$a<=>$b} keys %{$$self{ifcfgs}};
        $next_seq = $sequences[-1]+1;
    }
    my $device = $self->interface.':'.$next_seq;
    my $new_cfg = $$self{cfg_path}.'ifcfg-'.$device;
    $$self{m}->info('create virtual network '.$new_cfg);
    open (my $fh, '>', $new_cfg);
    print $fh "BOOTPROTO=dhcp\n";
    print $fh "DEFROUTE=yes\n";
    print $fh "PEERDNS=yes\n";
    print $fh "PEERROUTES=yes\n";
    print $fh "IPV4_FAILURE_FATAL=no\n";
    print $fh "DEVICE=$device\n";
    print $fh "ONBOOT=yes\n";
    close $fh;
    %{$$self{ifcfgs}->{$next_seq}} = (device=>$device, abs_path=>$new_cfg, obtained_ip=>'');
    my $obtained_ip = $self->interface_up($device);
    $self->exec("echo '#obtained_ip=$obtained_ip' >> $new_cfg");
}

sub interface_up {
    my ($self, $device) = @_;
    my $cmd = 'ifup '.$device;
    my $ip = '';
    $self->exec($cmd);
    if ($self->is_success) {
        $ip = $self->get_interface_last_ip();
        # should provent no new interface is up at this time
        $$self{m}->info($device.' is up '.$ip);
    } else {
        $$self{m}->error('ifup '.$device.'failed');
        $$self{m}->error($self->out);
    }
    return $ip;
}

sub get_interface_ip {
    my $self = shift;
    my $interface = $self->interface;
    my $cmd = "ip addr show $interface|sed -ne 's/ *inet \\(.*\\) brd .* global secondary dynamic $interface/\\1/gp'";
    $self->exec($cmd);
    my @ips = split('\s+', $self->out);
    foreach (0..$#ips) {
        $ips[$_] =~ s/\/\d+//;
    }
    return @ips;
}

sub get_interface_last_ip {
    my $self = shift;
    my $interface = $self->interface;
    my $cmd = "ip addr show $interface|sed -ne 's/ *inet \\(.*\\) brd .* global secondary dynamic $interface/\\1/gp'|tail -n1";
    $self->exec($cmd);
    my $ip = $self->out;
    chomp($ip);
    $ip =~ s/\/\d+//;
    return $ip;
}

sub interface_down {
    my ($self, $device) = @_;
    my $cmd = 'ifdown '.$device;
    $self->exec($cmd);
    if ($self->is_success) {
        $$self{m}->info($device.' is down');
    } else {
        $$self{m}->error('ifdown '.$device.'failed');
        $$self{m}->error($self->out);
    }
}

sub remove_interface_ip {
    my ($self, $interface, $ip) = @_;
    my $cmd = "ip addr show $interface|sed -ne 's/ *inet \\($ip.*\\) brd .* global secondary dynamic $interface/\\1/gp'";
    $self->exec($cmd);
    my $ifaddr = $self->out;
    chomp($ifaddr);
    $cmd = "ip addr del $ifaddr dev $interface";
    $self->exec($cmd);
}

sub remove_virtual_network {
    my ($self, $ip) = @_;
    # get cfg file name: grep ip
    my $cfg = '';
    my $device = '';
    my $obtained_ip = '';
    foreach my $seq (sort keys %{$$self{ifcfgs}}) {
        if ($ip eq $$self{ifcfgs}->{$seq}->{obtained_ip}) {
            $cfg = $$self{ifcfgs}->{$seq}->{abs_path};
            $device = $$self{ifcfgs}->{$seq}->{device};
            $obtained_ip = $$self{ifcfgs}->{$seq}->{obtained_ip}; 
        }
    }
    # get device name. interface down
    $self->interface_down($device);
    # remove interface ip
    $self->remove_interface_ip($self->interface, $obtained_ip);
    # delete cfg file
    unlink $cfg;
}

1;
