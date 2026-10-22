################################################################################
# Replace zabbix-agent and/or Configure zabbix-agent2
# See module linuxbeheerscript for som additional UserParameters and scripts
################################################################################
class team_linux::profile::zabbix_agent2 inherits team_linux::profile::parameters {

  $zabbix_agent = lookup ( { name => 'team_linux::zabbix_agent', value_type => String, merge => 'deep', default_value => 'zabbix-agent2' } )

  $all_repos  = $facts['repositories'].keys()
  $zbx_repoid =  $all_repos.filter | $repoarray | { $repoarray =~ '^CAK_Zabbix.*LTS.*' }
  $zabbix_reponame = $zbx_repoid[0]
  #notify {"Zabbix repository: $zabbix_reponame":}
  $zabbix_repostatus = $facts['repositories'][$zabbix_reponame]
  #notify {"Zabbix repository status: $zabbix_repostatus":}
  if $zabbix_repostatus == 'disabled' {
    notify {"Enabling Zabbix repository: $zabbix_reponame":}
    exec { 'enable_zabbix_repo':
      command => "subscription-manager repos --enable ${zabbix_reponame}",
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      provider => 'shell',
   }
  }

  if $zabbix_agent == 'zabbix-agent2' {
    $zabbix_fqdn = lookup( { name => "team_linux::zabbix_fqdn",
                             default_value => undef } )
    $zabbix_ip   = lookup( { name => "team_linux::zabbix_ip",
                             default_value => undef } )
    $zabbix_url  = lookup( { name => "team_linux::zabbix_url",
                             default_value => undef } )

    $userparameters = lookup({name => 'team_linux::zabbix_userparams', merge => 'hash'})
    $zabbix_additional_userparams  = lookup({ name => 'linuxbeheerscripts::zabbix_additional_userparams', merge => 'hash', default_value => undef })

    if ( $facts['os']['family'] == 'RedHat' ) {
      $zabbix_service     = 'zabbix-agent'
      $conf_include       = '/etc/zabbix/zabbix_agent2.d'
      $base_conf          = "${conf_include}/base.conf"
      $allowkeys          = "${conf_include}/allowkeys.conf"
      $zabbix_agent2_conf = '/etc/zabbix/zabbix_agent2.conf'

      if Integer($facts['os']['release']['major']) < 9 {
        # Make sure zabbix-agent is removed
        # for some reason, the following doesn't do the trick
        #      if defined(Package[zabbix-agent]) {
        #        package{'zabbix-agent':
        #          ensure => absent,
        #        }
        #      }
        exec {'check_presence_/usr/sbin/zabbix_agentd':
          command => '/bin/true',
          onlyif => '/usr/bin/test -x /usr/sbin/zabbix_agentd',
        } ->
        exec { 'stop-zabbix-agent':
          command     => 'systemctl stop zabbix-agent',
          path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
          onlyif      => '/usr/bin/test -x /usr/sbin/zabbix_agentd',
          require     => Exec['check_presence_/usr/sbin/zabbix_agentd'],
        } ->
        package{'zabbix-agent':
          ensure => absent,
        }
      }

      # Ugly workaround for the Puppet-server for unknown reason not finding the
      # already created User resource we are looking for ...
      exec {'check_zabbix':
        command  => 'true',
        unless   => 'grep -v zabbix /etc/passwd',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      } ->
      if ! defined(Package[zabbix-agent2]) {
        package{ 'zabbix-agent2':
          ensure => present,
        }
      } -> # Make sure the dirs exist and are owned by user zabbix
      file{ [ '/var/log/zabbix', '/run/zabbix', "${conf_include}", ]:
        ensure => directory,
        owner  => zabbix,
        group  => zabbix,
        force  => true,
        mode   => '0755',
      } -> # after upgrade / move make sure log file is owned by zabbix
      file{ [ '/var/log/zabbix/zabbix_agent2.log', ]:
        owner  => zabbix,
        group  => zabbix,
        force  => true,
        mode   => '0664',
      }
      file{ '/etc/logrotate.d/zabbix_monitorfiles':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    =>  '0640',
        content => template('team_linux/zabbix_logrotate_syslog.erb'),
     }
      # just in case the uid has been changed after package installation, use somthing like:
#    # make sure directories are owned by the user zabbix (after package installation and local account configuration)
#    exec {"check_${logname}_dirs":
#      command   => "chown -R zabbix:zabbix /var/{log,run}/zabbix",
#      unless    => "stat --format=%U:%G /var/{log,run}/zabbix | egrep zabbix:zabbix",
#      path      => ['/usr/bin','/usr/sbin','/bin','/sbin'],
#      loglevel  => 'info',
#      logoutput => 'on_failure',
#      provider  => 'shell',
#      timeout   => 0,
#    }


    } else {
      $zabbix_service = undef
      $zabbix_agent2_conf = undef
    }

    # Home-directory already defined by "localaccount.pp" (but not created?)
    # Just make sure the homedir exists and belongs to zabbix
    #   (Puppet 'user' resource?)
    exec { 'create_/var/lib/zabbix':
      command  => 'mkdir /var/lib/zabbix',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
      unless   => '/bin/ls -d /var/lib/zabbix >/dev/null 2>&1',
      provider => 'shell',
    } ->
    exec { 'check_/var/lib/zabbix':
      command  => 'chown -R zabbix: /var/lib/zabbix',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin', ],
      unless   => 'stat --format %U:%G /var/lib/zabbix|grep zabbix:zabbix >/dev/null 2>&1',
      provider => 'shell',
    }

    file_line { 'Server':
      ensure  => present,
      line    => "Server=${zabbix_ip}",
      path    => '/etc/zabbix/zabbix_agent2.conf',
      match   => '^Server=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service["${zabbix_service}"],
    }

    file_line { 'ServerActive':
      ensure  => present,
      line    => "ServerActive=${zabbix_url}",
      path    => '/etc/zabbix/zabbix_agent2.conf',
      match   => '^ServerActive=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service["${zabbix_service}"],
    }

    # For server, set "Visible name" to "Zabbix server" via the GUI!
    file_line { 'Hostname':
      ensure  => present,
      line    => "Hostname=${facts['networking']['fqdn']}", 
      path    => '/etc/zabbix/zabbix_agent2.conf',
      match   => '^Hostname=.*',
      replace => true,
      replace_all_matches_not_matching_line => true,
      notify  => Service["${zabbix_service}"],
    }

    # See linuxbeheerscripts for user parameters and other scripts!
    # Some base settings and legacy user parameters go in the following include
    file{ "${base_conf}":
      owner => root,
      group => root,
      mode => '0644',
      notify  => Service["${zabbix_service}"],
      require => File["${conf_include}"],
      content => template('team_linux/zabbix_agent2.conf.erb'),
    }
    file{ '/etc/zabbix/zabbix_agent2.d/userparams.conf':
      owner => root,
      group => root,
      mode => '0644',
      notify  => Service["${zabbix_service}"],
      require => File["${conf_include}"],
      content => template('linuxbeheerscripts/zabbix_userparams.conf.erb'),
    }

    # zabbix-agent2 needs an AllowKey per server initiated script
    file{ "${allowkeys}":
      owner => root,
      group => root,
      mode => '0644',
      notify  => Service["${zabbix_service}"],
      require => File["${conf_include}"],
      content => template('team_linux/zabbix_agent_allowkey.erb'),
    }

    $awkargs = '/zabbix/ {if($1 == "zabbix" && $2 == "staff_u") print $2}'
    $awkargsstring = shellquote($awkargs)
    # Try to exclude non-current RHEL minor releases 
    if $facts['selinux'] and ( ( $rhelmajor < 9 and $rhelminor >= 6 ) or $rhelmajor  >= 9 ) {
      exec { 'zabbix_selinuxrole':
        command => 'usermod -Z staff_u zabbix',
        path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        unless  => "semanage login -l | awk ${awkargsstring} | grep staff_u",
        provider => 'shell',
      }
      # Relabel /var/lib/zabbix if needed, policy should contain correct label
      selboolean { 'domain_can_mmap_files':
        persistent => true,
        value => on,
      }
      # Make sure 'zabbix_run_sudo' is true
      selboolean { 'zabbix_run_sudo':
        persistent => true,
        value => on,
      }
    }

    if $facts['selinux'] and ( ( $rhelmajor < 9 and $rhelminor >= 6 ) or $rhelmajor  >= 9 ) {
      service{ "${zabbix_service}":
        name   => 'zabbix-agent2',
        ensure => running,
        enable => true,
        require => [ Package['zabbix-agent2'], File['/var/log/zabbix'], File['/var/log/zabbix/zabbix_agent2.log'], File['/run/zabbix'], Exec['check_zabbix'], Exec['check_/var/lib/zabbix'],  Exec['create_/var/lib/zabbix'],  Exec['zabbix_selinuxrole'], ],
      }
    } else {
      service{ "${zabbix_service}":
        name   => 'zabbix-agent2',
        ensure => running,
        enable => true,
        require => [ Package['zabbix-agent2'], File['/var/log/zabbix'], File['/var/log/zabbix/zabbix_agent2.log'], File['/run/zabbix'], Exec['check_zabbix'], Exec['check_/var/lib/zabbix'],  Exec['create_/var/lib/zabbix'], ],
      }
    }

    # No need to include a logrotate config, zabbix-agent2 RPM provides one
    # if needed
    #file_line { 'MyParameter':
    #  ensure  => present,
    #  path    => '/etc/zabbix/zabbix_agent2.conf',
    #}
    # Remove old agent config
    file{ '/etc/logrotate.d/syslog-zabbix':
      ensure  => absent,
    }

  }
}
