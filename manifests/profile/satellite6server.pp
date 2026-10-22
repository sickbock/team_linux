################################################################################
# PostgreSQL database server on RHEL 8
# workaround missing dnf module support in Puppet 5 using 'exec' 
#   note: workaroune and tests are not optimal & require multiple Puppet runs
################################################################################
class team_linux::profile::satellite6server inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    # see parameters # $pgsqlvers = lookup({ name => 'team_linux::pgsqlvers', value_type => String, merge => 'first', default_value => undef  })
#    $backupusr = lookup({ name => 'team_linux::pgsqlbackupusr', value_type => String, merge => 'first', default_value => 'root'  })
#    $dbuser = lookup({ name => 'team_linux::pgsqldbuser', value_type => String, merge => 'first', default_value => 'postgres'  })
#    $pgcrontab = lookup({ name => 'team_linux::pgsqlcrontab', value_type => String, merge => 'first', default_value => "33 03 * * * root /usr/local/bin/pg_backup_rotated.sh >/var/log/pgbackup.log 2>&1\n"  }) # add explicit newline, otherwise cron ignors the line entirely
    $diskdev1   = '/dev/sdb'
    $diskdev2   = '/dev/sdc'
    $diskdev3   = '/dev/sdd'
    $diskdev4   = '/dev/sde'
    $diskdev5   = '/dev/sdf'
    $diskdev6   = '/dev/sdg'
    $diskdev7   = '/dev/sdh'
    $dirwww     = '/var/www'
    $dirhtml    = '/var/www/html'
    $dirpub     = '/var/www/html/pub'
    $dirinstall = '/var/www/html/pub/install'
    $mpcacheplp = '/var/cache/pulp'
    $mpdata     = '/data'
    $mppgsql    = '/var/lib/pgsql'
    $mppulp     = '/var/lib/pulp'
    $mpqpidd    = '/var/lib/qpidd'
    $mpsplunkin = '/var/www/html/pub/install/splunk' 
    $mpbackup   = '/backup_satellite'
    $vgdata     = 'vgsat-data'
    $vgbackup  = 'vgsat-backup'
    $lvcacheplp = 'lvvarcachepulp'
    $lvdata     = 'lvdata'
    $lvpgsql    = 'lvvarlibpgsql'
    $lvpulp     = 'lvvarlibpulp'
    $lvqpidd    = 'lvqpidd'
    $lvsplunkin = 'lvinstallsplunk'
    $lvbackup   = 'lvbackup'
    $filesys    = 'xfs'
    $szcacheplp = lookup({ name => 'team_linux::szcacheplp', value_type => String, merge => 'first', default_value => '5G'  })
    $szdata     = lookup({ name => 'team_linux::szdata', value_type => String, merge => 'first', default_value => '20G'  })
    $szpgsql    = lookup({ name => 'team_linux::szpgsql', value_type => String, merge => 'first', default_value => '30G'  })
    $szpulp     = lookup({ name => 'team_linux::szpulp', value_type => String, merge => 'first', default_value => '750G'  })
    $szqpidd    = lookup({ name => 'team_linux::szqpidd', value_type => String, merge => 'first', default_value => '10G'  })
    $szsplunkin = lookup({ name => 'team_linux::szsplunkin', value_type => String, merge => 'first', default_value => '20G'  })
    $szbackup   = lookup({ name => 'team_linux::szbackup', value_type => String, merge => 'first', default_value => '1T'  })
#    $szcacheplp = lookup({ name => 'team_linux::szcacheplp', value_type => String, merge => 'first', default_value => '1G'  })
#    $szdata     = lookup({ name => 'team_linux::szdata', value_type => String, merge => 'first', default_value => '2G'  })
#    $szpgsql    = lookup({ name => 'team_linux::szpgsql', value_type => String, merge => 'first', default_value => '1G'  })
#    $szpulp     = lookup({ name => 'team_linux::szpulp', value_type => String, merge => 'first', default_value => '3G'  })
#    $szqpidd    = lookup({ name => 'team_linux::szpulp', value_type => String, merge => 'first', default_value => '1G'  })
#    $szsplunkin = lookup({ name => 'team_linux::szsplunkin', value_type => String, merge => 'first', default_value => '2G'  })
#    $szbackup   = lookup({ name => 'team_linux::szbackup', value_type => String, merge => 'first', default_value => '1G'  })
    $compvers   = String($facts['postgresmodule'])

    # create mountpoint
    file { [ "${mpcacheplp}", "${mpdata}", "${mppgsql}", "${mppulp}", "${mpqpidd}", "${mpsplunkin}", "${mpbackup}", "${dirwww}", "${dirhtml}", "${dirpub}", "${dirinstall}", ]:
      ensure => directory,
    } ->
    if $facts['disks']['sdb'] and $facts['disks']['sdc'] and $facts['disks']['sdd'] and $facts['disks']['sde'] and $facts['disks']['sdf'] and $facts['disks']['sdg'] and $facts['disks']['sdh'] {

      exec{'check_diskdevs':
        command  => "hdparm -z ${diskdev1} ${diskdev2} ${diskdev3} ${diskdev4} ${diskdev5} ${diskdev6} ${diskdev7}",
        timeout  => 0,
        unless   => "pvs ${diskdev1} ${diskdev2} ${diskdev3} ${diskdev4} ${diskdev5} ${diskdev6} ${diskdev7}",
        provider => 'shell',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      } ~>
      class { 'lvm':
        volume_groups => {
          "${vgdata}" => {
            createonly => true,
            physical_volumes => [ "${diskdev1}", "${diskdev2}", "${diskdev3}", "${diskdev4}", "${diskdev5}", "${diskdev6}", ],
          },
          "${vgbackup}" => {
            createonly => true,
            physical_volumes => [ "${diskdev7}", ],
          },
        },
        require => [ Exec['check_diskdevs'],
                     File["${mpcacheplp}"], File["${mpdata}"], File["${mppgsql}"], File["${mppulp}"], File["${mpqpidd}"], File["${mpsplunkin}"], ],
      } ~>
      logical_volume { "${lvcacheplp}":
        ensure        => present,
        volume_group  => "${vgdata}",
        stripes       => 2,
        stripesize    => 128,
        size          => "${szcacheplp}",
      } ~>
      filesystem { "/dev/${vgdata}/${lvcacheplp}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mpcacheplp}":
        name    => "${mpcacheplp}",
        device  => "/dev/${vgdata}/${lvcacheplp}",
        fstype  => "${filesys}",
        ensure  => mounted,
      } ~>
      logical_volume { "${lvdata}":
        ensure        => present,
        volume_group  => "${vgdata}",
        stripes       => 2,
        stripesize    => 128,
        size          => "${szdata}",
      } ~>
      filesystem { "/dev/${vgdata}/${lvdata}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mpdata}":
        name    => "${mpdata}",
        device  => "/dev/${vgdata}/${lvdata}",
        fstype  => "${filesys}",
        ensure  => mounted,
      } ~>
      logical_volume { "${lvpgsql}":
        ensure        => present,
        volume_group  => "${vgdata}",
        stripes       => 2,
        stripesize    => 128,
        size          => "${szpgsql}",
      } ~>
      filesystem { "/dev/${vgdata}/${lvpgsql}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mppgsql}":
        name    => "${mppgsql}",
        device  => "/dev/${vgdata}/${lvpgsql}",
        fstype  => "${filesys}",
        ensure  => mounted,
      } ~>
      logical_volume { "${lvpulp}":
        ensure        => present,
        volume_group  => "${vgdata}",
        stripes       => 2,
        stripesize    => 128,
        size          => "${szpulp}",
      } ~>
      filesystem { "/dev/${vgdata}/${lvpulp}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mppulp}":
        name    => "${mppulp}",
        device  => "/dev/${vgdata}/${lvpulp}",
        fstype  => "${filesys}",
        ensure  => mounted,
      } ~>
      logical_volume { "${lvqpidd}":
        ensure        => present,
        volume_group  => "${vgdata}",
        stripes       => 2,
        stripesize    => 128,
        size          => "${szqpidd}",
      } ~>
      filesystem { "/dev/${vgdata}/${lvqpidd}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mpqpidd}":
        name    => "${mpqpidd}",
        device  => "/dev/${vgdata}/${lvqpidd}",
        fstype  => "${filesys}",
        ensure  => mounted,
      } ~>
      logical_volume { "${lvsplunkin}":
        ensure        => present,
        volume_group  => "${vgdata}",
        stripes       => 2,
        stripesize    => 128,
        size          => "${szsplunkin}",
      } ~>
      filesystem { "/dev/${vgdata}/${lvsplunkin}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mpsplunkin}":
        name    => "${mpsplunkin}",
        device  => "/dev/${vgdata}/${lvsplunkin}",
        fstype  => "${filesys}",
        ensure  => mounted,
      } ~>
      logical_volume { "${lvbackup}":
        ensure        => present,
        volume_group  => "${vgbackup}",
        stripes       => 1,
        stripesize    => 128,
        size          => "${szbackup}",
      } ~>
      filesystem { "/dev/${vgbackup}/${lvbackup}":
        ensure  => present,
        fs_type => "${filesys}",
      } ~>
      mount { "${mpbackup}":
        name    => "${mpbackup}",
        device  => "/dev/${vgbackup}/${lvbackup}",
        fstype  => "${filesys}",
        ensure  => mounted,
      }
    } else {
      fail( "This role requires RHEL 8 or later with at least 7 disks in addition to 'sda' " )
      } 
  }
  file { [ "/root/git", "/root/git/patching", "/root/git/satellite", ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775'
  }
  file { [ "/data/nodes", ]:
    ensure => directory,
    owner  => 'root',
    group  => 'vro-plugin',
    mode   => '0775'
  }
  file { [ "/data/remove-nodes-imported", ]:
    ensure => directory,
    owner  => 'deletenodes',
    group  => 'deletenodes',
    mode   => '0755'
  }
  file { [ "/data/remove-nodes-notinsatellite", ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }
  file { [ "/data/remove-nodes-logging", ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }
  file { [ "/data/repos", "/data/repos/gitlab", "/data/repos/gitlab/el8" ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }
#  file { '/etc/yum.repos.d/gitlab.repo':
#  content => template( 'team_linux/satellite_gitlab.repo.rb' ),
#  ensure  => present,
#  owner   => root,
#  group   => root,
#  mode    => '0644',
#  }
   file { '/etc/yum.repos.d/gitlab.repo':
     ensure  => absent,
   }
#  file { [ "/root/scripts", "/root/scripts/create-host-collections" ]:
#    ensure => directory,
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0750'
#  }
#  file { '/root/scripts/create-host-collections/create-host-collections.sh':
#  content => template( 'team_linux/satellite_create-host-collections.sh.erb' ),
#  ensure  => present,
#  owner   => root,
#  group   => root,
#  mode    => '0750',
#  }
  file { [ "/root/cronscripts", ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775'
  }
  file { '/root/cronscripts/remove-nodes.sh':
    content => template ( 'team_linux/satellite_remove-nodes.sh.erb' ),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }
  file { '/root/cronscripts/satellite-healthcheck.sh':
    content => template ( 'team_linux/satellite_healthcheck.sh.erb' ),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }
  file { '/root/cronscripts/hypervisor-subscription-overview.sh':
    content => template ( 'team_linux/satellite_hypervisor-subscription-overview.sh.erb' ),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }
  file { '/root/cronscripts/tmds2sat.sh':
    content => template ( 'team_linux/satellite_tmd2sat.sh.erb' ),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }
  file { '/root/cronscripts/sendreports.sh':
    content => template ( 'team_linux/satellite_sendreports.sh.erb' ),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }
  file { '/root/cronscripts/obsolence_report.sh':
    content => template ( 'team_linux/satellite_obsolence_report.sh.erb' ),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0750'
  }
  file { '/etc/cron.d/satellite':
  content => template( 'team_linux/satellite_cron.erb' ),
  ensure  => present,
  owner   => root,
  group   => root,
  mode    => '0644',
  }
}
