################################################################################
# install PostgreSQL and create Zabbix 7.0 LTS server on RHEL 9
################################################################################
class team_linux::profile::zabbix7server inherits team_linux::profile::parameters {

  $zabbixurl = lookup({ name => 'team_linux::zabbixurl', merge => 'deep', default_value => '/zabbix/' })
  $zabbixphp = lookup({ name => 'team_linux::zabbixphp', merge => 'deep', default_value => '7.4' })
  $zabbxpsql = lookup({ name => 'team_linux::zabbxpsql', merge => 'deep', default_value => '13' })
  $diskdev1  = lookup({ name => 'team_linux::zabbxpsqld1', merge => 'deep', default_value => '/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:1:0' }) # use virtual hardware specific path since using /dev/sdb is unreliable
  $diskdev2  = lookup({ name => 'team_linux::zabbxpsqld2', merge => 'deep', default_value => '/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:2:0' }) # use virtual hardware specific path since using /dev/sdc is unreliable
  $compvers  = String($facts['postgresmodule'])

  # Enable non-supported repo
  $all_repos  = $facts['repositories'].keys()
  $zbx_nonsup =  $all_repos.filter | $repoarray | { $repoarray =~ '^CAK_Zabbix.*non-supported.*' }
  $zabbix_nonsupname = $zbx_nonsup[0]
  #notify {"Zabbix repository: $zabbix_nonsupname":}
  $zabbix_repostatus = $facts['repositories'][$zabbix_nonsupname]
  #notify {"Zabbix repository status: $zabbix_repostatus":}
  if $zabbix_repostatus == 'disabled' {
    notify {"Enabling Zabbix repository: $zabbix_nonsupname":}
    exec { 'enable_zabbix_server_repo':
      command => "subscription-manager repos --enable ${zabbix_nonsupname}",
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      provider => 'shell',
   }
  }

 
  if ( $facts['os']['family'] == 'RedHat' and $rhelmajor >= 9 ) {

    # https://www.zabbix.com/download?zabbix=7.0&os_distribution=red_hat_enterprise_linux&os_version=9&components=server_frontend_agent&db=pgsql&ws=apache
    # install zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
    # where zabbix-agent2 is installed by the appropriate class
    # install Apache and PHP in the the default versions on RHEL 9
    if ! defined(Package[httpd]) {
      package {'httpd':
        ensure => present,
      }
    } ->
    if ! defined(Package[mod_ssl]) {
      package {'mod_ssl':
        ensure => present,
      }
    } ->
    if ! defined(Package[php]) {
      package {'php':
        ensure => present,
      }
    } ->
    file { '/usr/share/httpd':
      ensure => directory,
      owner  => 'apache',
      group  => 'apache',
      mode   => '0755'
    } 
    if ! defined(Package[zabbix-server-pgsql]) {
      package{ 'zabbix-server-pgsql':
        ensure => present,
      }
    }
    if ! defined(Package[zabbix-web-pgsql]) {
      package{ 'zabbix-web-pgsql':
        ensure => present,
      }
    }
    if ! defined(Package[zabbix-apache-conf]) {
      package{ 'zabbix-apache-conf':
        ensure => present,
      }
    }
    if ! defined(Package[zabbix-sql-scripts]) {
      package{ 'zabbix-sql-scripts':
        ensure => present,
      }
    }
    if ! defined(Package[zabbix-selinux-policy]) {
      package{ 'zabbix-selinux-policy':
        ensure => present,
      }
    }
    if ! defined(Package[zabbix-get]) {
      package{ 'zabbix-get':
        ensure => present,
      }
    }

    $vgname    = 'zabbix-vg'
    $lvdata    = 'zabbixdata-lv'
    $lvbackup  = 'zabbixbackup-lv'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::zabbixlogsize', value_type => String, merge => 'first', default_value => '380G'  })
    $szbackup  = lookup({ name => 'team_linux::zabbixbackupsize', merge => 'unique', default_value => '20G'  })
    $mpdata    = '/var/lib/pgsql'
    $mpbackup  = '/var/lib/pgsql_backup'

    $pvname = "lvm_vg_${vgname}_pvs"
    #notify { "PV: ${facts[$pvname]}":} 
    if  $vgname in $facts['volume_groups'] {
      $physvs = $facts["${pvname}"] # note: should be CSV whith two PV's
      $physv  = $physvs.split(',')  # To do: conditional check if CSV or not
    } else {
      $physv = [ "${diskdev1}", "${diskdev2}", ]
    }
    #notify{"PV in ${vgname} is ${physv} ":}
    
    exec{'check_diskdevs':
      command => "hdparm ${diskdev1} ${diskdev2}",
      timeout  => 0,
      unless => "grep ready /var/lib/provisioning/state",
      path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    } ~>
    file { [ "${mpdata}", "${mpbackup}",]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775'
    } ~>
    class { 'lvm':
      volume_groups => {
        "${vgname}" => {
          createonly => true,
          physical_volumes => $physv,
        },
      },
    } ~>
    logical_volume { "${lvdata}":
      ensure        => present,
      volume_group  => "${vgname}",
      stripes       => 2,
      stripesize    => 128,
      size          => "${szdata}",
    } ~>
    filesystem { "/dev/${vgname}/${lvdata}":
      ensure  => present,
      fs_type => "${filesys}",
    } ~>
    mount { "${mpdata}":
      name    => "${mpdata}",
      device  => "/dev/${vgname}/${lvdata}",
      fstype  => "${filesys}",
      ensure  => mounted,
    } ~>
    logical_volume { "${lvbackup}":
      ensure        => present,
      volume_group  => "${vgname}",
      stripes       => 2,
      stripesize    => 128,
      size          => "${szbackup}",
    } ~>
    filesystem { "/dev/${vgname}/${lvbackup}":
      ensure  => present,
      fs_type => "${filesys}",
    } ~>
    mount { "${mpbackup}":
      name    => "${mpbackup}",
      device  => "/dev/${vgname}/${lvbackup}",
      fstype  => "${filesys}",
      ensure  => mounted,
    } 
    
#    file { '/etc/cron.daily/housekeeping.sh':
#      content => template( 'team_linux/zabbix_housekeeping.sh.erb' ),
#      ensure  => present,
#      owner   => root,
#      group   => root,
#      mode    => '0554',
#    }

    if $facts['os']['selinux'] {
      selboolean { 'httpd_can_connect_zabbix':
        persistent => true,
        value => on,
      }
      selboolean { 'httpd_can_network_connect_db':
        persistent => true,
        value => on,
      }
      selboolean { 'httpd_can_connect_ldap':
        persistent => true,
        value => on,
      }
#      exec { 'zabbix_t_permissive':
#        command  => 'semanage permissive -a zabbix_t',
#        provider => 'shell',
#        unless   => 'semanage permissive -l |grep zabbix_t',
#        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#      }
    }

    file { '/var/www/html/index.html':
      content => template( 'team_linux/zabbix_index.html.erb' ),
      ensure  => present,
      owner  => 'apache',
      group  => 'apache',
      mode    => '0444',
      notify => Service['apache'],
    }

    service{ 'apache':
      name    => 'httpd',
      ensure  => running,
      enable  => 'true',
      require => Package['httpd'],
    }

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
