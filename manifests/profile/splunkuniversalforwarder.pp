class team_linux::profile::splunkuniversalforwarder inherits team_linux::profile::parameters {

  $splunkfwdversion   = lookup( { name => 'team_linux::splunkforwarderversion',
                             default_value => undef } )
  $hasuniversalforwarder = lookup( { name => "team_linux::hasuniversalforwarder",
                           default_value => false } )
  $satellite = lookup({ name => 'team_linux::satellite_server', default_value => 'satellite.cak-bz.local' })
  $download_base = lookup({ name => 'team_linux::download_base', default_value => 'pub/install' })
  $splunk_base = lookup({ name => 'team_linux::splunk_base', default_value => 'splunk' })

  $splunkpkg = lookup({name => 'team_linux::splunk_package', default_value => undef })

  if $hasuniversalforwarder == true {


    # Ugly workaround for the Puppet-server for unknown reason not finding the
    # already created User resource we are looking for ...
    exec {'check_splunk':
      command  => 'true',
      unless   => 'grep -v splunk /etc/passwd',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    } ->
    if defined('$splunkfwdversion') and defined('$splunkpkg') {
      exec{'install_splunkforwarder':
        command  => "/bin/yum -y install https://${satellite}/${download_base}/${splunk_base}/${splunkpkg}",
        logoutput => true,
        refreshonly  => true,
        notify  => Service['splunkforwarder'],
        path => [ '/sbin', '/bin', '/usr/bin' ],
        unless => "rpm -q  splunkforwarder | grep ${splunkfwdversion}",
        provider => 'shell',
      }
    } else {
      notice("Parameters splunkforwarderversion or splunk_package are undefined or role is wrong!")
    } ->
    file { '/lib/systemd/system/splunkforwarder.service':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('team_linux/splunkforwarder.service.erb'),
      require => Exec['check_splunk'],
    } ~>
    exec { 'splunkforwarder-systemd-reload':
      command     => 'systemctl daemon-reload',
      path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
      refreshonly => true,
    } ~>
    exec { 'splunkforwarder-accept-license':
      command     => 'su -s /bin/bash -c "/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt" - splunk',
      path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
      refreshonly => true,
      require => Exec['check_splunk'],
    } ~>
    service { 'splunkforwarder':
      enable   => true,
      provider => systemd,
      require  => Exec['check_splunk', 'splunkforwarder-accept-license', ],
    }

  }
}
