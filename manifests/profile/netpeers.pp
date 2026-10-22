class team_linux::profile::netpeers {

  $netpeer_svg_window_days = lookup ({ name => 'team_linux::profile::netpeer_svg_window_days', default_value => 14 })
  $netpeers_key = lookup ({ name => 'team_linux::netpeers_private', default_value => undef })
  $vroplugin_key = lookup ({ name => 'team_linux::netpeers_vro-plugin_private', default_value => undef })

  if ! defined(Package['graphviz']) {
    package { 'graphviz':
      ensure => installed,
    }
  }

  if ! defined(Package['rsync']) {
    package { 'rsync':
      ensure => installed,
    }
  }

  file { [ '/etc/netpeers', '/etc/netpeers/.ssh', ]:
    ensure => directory,
    owner   => 'apache',
    group  => 'apache',
    mode   => '0750',
  } ->
  file { '/etc/netpeers/.ssh/id_ed25519_netpeers':
    ensure => file,
    owner  => 'apache',
    group  => 'apache',
    mode   => '0600',
    content => inline_epp($netpeers_key),
  } ->
  file { '/etc/netpeers/.ssh/id_ed25519_vro-plugin':
    ensure => file,
    owner  => 'apache',
    group  => 'apache',
    mode   => '0600',
    content => inline_epp($vroplugin_key),
  } ->
  file { '/etc/netpeers/managed_nodes':
    owner => 'apache',
    group => 'apache',
    source => 'puppet:///files/managed_nodes',
  } ->
  file {'/usr/local/bin/netpeers_gather.sh':
    owner => 'apache',
    group => 'apache',
    mode  => '0550',
    content => template('linuxbeheerscripts/netpeers_gather.sh.erb'),
  } ->
  file { [ '/var/www/html/enc', '/var/www/html/enc/ce', '/var/www/html/enc/pe', ]:
    ensure => directory,
    owner  => 'apache',
    group  => 'apache',
    mode   => '0755',
  } ->
  file { '/usr/local/bin/yq':
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template( 'linuxbeheerscripts/puppetmaster/yq.erb')
  } ->
  file {'/var/www/html/netpeers.css':
    owner   => 'apache',
    group   => 'apache',
    mode    => '0550',
    content => template('linuxbeheerscripts/netpeers.css.erb'),
  } ->
  file {'/usr/local/bin/netpeers_gen_html.sh':
    owner   => 'apache',
    group   => 'apache',
    mode    => '0550',
    content => template('linuxbeheerscripts/netpeers_gen_html.sh.erb'),
  } ->
  file {'/etc/cron.d/netpeers':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('team_linux/netpeers_cron.erb'),
  }

}
