package HttpdSSLConf;

use strict;
use warnings;
use Cwd;
use Getopt::Std;

BEGIN {unshift @INC, getcwd()}
use Message;
use parent 'Command';


my $ssl_conf = './template/httpd-ssl.conf.sample';
my $m = Message->new(level=>'info');


sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    return $self;
}

sub create_httpd_ssl_conf {
    # generate unique stings based on proxy server's ip address 
    my ($self, $ip, $target_srv) = @_;
    my @numbers = split('\.', $ip);
    my @conf_new_lines;
    my $new_conf = "./conf/httpd-ssl.conf.$ip";
    my $serial_number = substr(join('', split('\.', $ip)), -6);
    my $san_principal_switch = join(':', $serial_number =~ /(\d{2})/g);

    # Add more Substitute rules or url rewrite rules
    push @conf_new_lines, qq(Substitute "s/$target_srv/$ip/");
    push @conf_new_lines, qq(Substitute "s/\\"principalSwitch\\":\\"(.{15}).{8}/\\"principalSwitch\\":\\"\$1$san_principal_switch/");

    my @ssl_conf_lines;
    $$self{m}->info("creating new httpd ssl conf $new_conf");
    open(my $fh, '<', $ssl_conf) or die "$!"; 
    while (<$fh>) {
        chomp;
        push @ssl_conf_lines, $_;
    }
    close $fh;

    # create new conf file
    open($fh, '>', $new_conf) or die "$!";
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

