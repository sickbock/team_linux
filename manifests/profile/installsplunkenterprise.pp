class team_linux::profile::installsplunkenterprise inherits team_linux::profile::parameters {

  $splunkenterpriseversion   = lookup( { name => 'team_linux::splunkenterpriseversion',
                             default_value => undef } )
  $satellite = lookup({ name => 'team_linux::satellite_server', default_value => 'satellite.cak-bz.local' })
  $download_base = lookup({ name => 'team_linux::download_base', default_value => 'pub/install' })
  $splunk_base = lookup({ name => 'team_linux::splunk_base', default_value => 'splunk' })

  $splunkenterprisepkg = lookup({name => 'team_linux::splunkenterprise_package', default_value => undef })


  # Ugly workaround for the Puppet-server for unknown reason not finding the
  # already created User resource we are looking for ...
  exec {'check_splunk':
    command  => 'true',
    unless   => 'grep -v splunk /etc/passwd',
    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
  } ->
  if defined('$splunkenterpriseversion') and $defined('$splunkenterprisepkg') {
    exec{'install_splunkenterprise':
      command  => "/bin/yum -y install https://${satellite}/${download_base}/${splunk_base}/${splunkenterprisepkg}",
      logoutput => true,
      path => [ '/sbin', '/bin', '/usr/bin' ],
      #unless => "rpm -q  splunk | grep ${splunkenterpriseversion}",
      # require both mounted fs or package not installed / upgraded
      onlyif => "mountpoint /opt/splunk -q && ! rpm -qi splunk-${splunkenterpriseversion} >/dev/null",
      provider => 'shell',
    }
  } else {
    notice("Parameters splunkenterpriseversion or splunkenterprisepkg are undefined or role is wrong!")
  }

}
