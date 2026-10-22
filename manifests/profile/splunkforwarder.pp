class team_linux::profile::splunkforwarder inherits team_linux::profile::parameters {

  $splunkfwdversion   = lookup( { name => 'team_linux::splunkforwarderversion',
                             default_value => '8.0.5' } )
  $hassplunkforwarder = lookup( { name => "team_linux::hassplunkforwarder",
                           default_value => false } )

  if $hassplunkforwarder == true {

    # Ugly workaround for the Puppet-server for unknown reason not finding the
    # already created User resource we are looking for ...
    exec {'check_splunk':
      command  => 'true',
      unless   => 'grep -v splunk /etc/passwd',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    } ->
    if ! defined(Package[splunkforwarder]) {
      package{ 'splunkforwarder':
        name   => 'splunkforwarder',
        ensure => "${splunkfwdversion}",
      }
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
