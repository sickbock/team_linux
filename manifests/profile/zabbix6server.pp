################################################################################
# install PostgreSQL and create Zabbix 6.0 LTS server on RHEL 8
################################################################################
class team_linux::profile::zabbix6server inherits team_linux::profile::parameters {

  $zabbixurl = lookup({ name => 'team_linux::zabbixurl', merge => 'deep', default_value => '/zabbix/' })
  $zabbixphp = lookup({ name => 'team_linux::zabbixphp', merge => 'deep', default_value => '7.4' })
  $zabbxpsql = lookup({ name => 'team_linux::zabbxpsql', merge => 'deep', default_value => '13' })
  $compvers  = String($facts['postgresmodule'])

 
  if ( $facts['os']['family'] == 'RedHat' and $rhelmajor >= 8 ) {

    # install the default stream (Apache 2.4 on RHEL 8)
    exec { 'install_apache':
      command => 'dnf -y module install httpd/common',
      creates => '/var/www/cgi-bin',
      onlyif  => "egrep ${mpdata}'[     ]' /proc/mounts",
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    } # install the default stream (PHP 7.2 on RHEL 8)
    -> exec { 'install_php':
      command  => "dnf module enable php:${zabbixphp}; dnf distro-sync ; dnf -y module install php:${zabbixphp}",
      creates  => '/usr/sbin/php',
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      unless   => "php -v|grep ${zabbixphp} >/dev/null",
      provider => 'shell',
    }
    -> file { '/usr/share/httpd':
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

    $diskdev1  = '/dev/sdb'
    $diskdev2  = '/dev/sdc'
    $vgname    = 'zabbix-vg'
    $lvdata    = 'zabbixdata-lv'
    $lvbackup  = 'zabbixbackup-lv'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::zabbixlogsize', merge => 'unique', default_value => '380G'  })
    $szbackup  = lookup({ name => 'team_linux::zabbixbackupsize', merge => 'unique', default_value => '20G'  })
    $mpdata    = '/var/lib/pgsql'
    $mpbackup  = '/var/lib/pgsql_backup'

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
          physical_volumes => [ "${diskdev1}", "${diskdev2}", ],
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
    # install the PostgreSQL ${zabbxpsql} stream on RHEL 8
    # Still no documented support for dnf:
    # https://tickets.puppetlabs.com/browse/PUP-10235
    if "${compvers}X" != "${zabbxpsql}X" {
      exec { 'enable_postgresql_module':
        command  => "dnf -y module reset postgresql; dnf -y module enable postgresql:${zabbxpsql}; dnf -y distro-sync",
        provider => 'shell',
        unless   => 'test -x /usr/bin/postgres',
        onlyif   => "egrep ${mpdata}'[  ]' /proc/mounts",
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        require  => [ Mount["${mpdata}"], Mount["${mpbackup}"], ],
      }
    }

#    file { '/etc/cron.daily/housekeeping.sh':
#      content => template( 'team_linux/zabbix_housekeeping.sh.erb' ),
#      ensure  => present,
#      owner   => root,
#      group   => root,
#      mode    => '0554',
#    }

    if $facts['selinux'] {
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
      enable => 'true',
      require => Exec['install_apache'],
    }

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
