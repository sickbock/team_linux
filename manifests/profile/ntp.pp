################################################################################
#
# Manage ntp on RHEL 6, chrony on RHEL > 6
#
################################################################################
class team_linux::profile::ntp inherits team_linux::profile::parameters {
  $ntp_servers  = lookup({ name => 'team_linux::ntp_servers', value_type => Array[String], merge => 'deep', default_value => undef })

  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] < '7' ) {

    $driftfile = "/var/lib/ntp/drift"

    file { "/etc/ntp.conf":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'team_linux/ntp.conf.erb' ),
    }

    service{ "ntpd":
      ensure    => running,
      enable    => true,
      subscribe => [ File["/etc/ntp.conf"], ],
    }
  } elsif ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '7' ) {
    if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '9' ) {
      file_line { 'min_u_chrony':
        ensure  => present,
        line    => 'OPTIONS="-F 2 -u chrony"',
        path    => '/etc/sysconfig/chronyd',
        match   => '^OPTIONS=.*',
        replace => true,
        replace_all_matches_not_matching_line => true,
        notify  => Service['chronyd'],
      }
    }
    $driftfile = "/var/lib/chrony/drift"
    service{ "ntpd":
      ensure    => stopped,
      enable   => false,
    }
    file { "/etc/chrony.conf":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template( 'team_linux/chrony.conf.erb' ),
    }
    service{ "chronyd":
      ensure    => running,
      enable    => true,
      subscribe => [ File["/etc/chrony.conf"], ],
      require   => Service["ntpd"],
    }
  }
}
