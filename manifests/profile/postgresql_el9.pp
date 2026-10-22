################################################################################
# RHEL 9 provides PostgreSQL 15 since 9.2, supported until May 2028
# workaround missing dnf module support in Puppet 5 using 'exec' 
#   note: workaroune and tests are not optimal & require multiple Puppet runs
# Custom facts should resolve VMWare specific disks to kernel based device names
################################################################################
class team_linux::profile::postgresql_el9 inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '9' ) {

    $pgrh9vers = lookup({ name => 'team_linux::pgsqlrhel9vers', value_type => String, merge => 'first', default_value => '15' })
    $backupusr = lookup({ name => 'team_linux::pgsqlbackupusr', value_type => String, merge => 'first', default_value => 'root'  })
    $dbuser = lookup({ name => 'team_linux::pgsqldbuser', value_type => String, merge => 'first', default_value => 'postgres'  })
    $pgcrontab = lookup({ name => 'team_linux::pgsqlcrontab', value_type => String, merge => 'first', default_value => "33 03 * * * root /usr/local/bin/pg_backup_rotated.sh >/var/log/pgbackup.log 2>&1\n"  }) # add explicit newline, otherwise cron ignors the line entirely
    $mpdata    = '/var/lib/pgsql'
    $mpbackup  = '/var/lib/pgsql_backup'
    $backupdir = lookup({ name => 'team_linux::pgsqlbackupdir', value_type => String, merge => 'first', default_value => "${mpbackup}"  })
    $vgname    = 'pgsql-vg'
    $lvdata    = 'pgsql-data'
    $lvbackup  = 'pgsqlbackup-lv'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::szpgsqldata', value_type => String, merge => 'first', default_value => '20G'  })
    $szbackup  = lookup({ name => 'team_linux::szpgsqlbackup', value_type => String, merge => 'first', default_value => '20G'  })
    $compvers  = String($facts['postgresmodule'])
    $diskname1 = String($facts['vmwc0t0d1'])
    $diskname2 = String($facts['vmwc0t0d2'])
    $diskdev1  = "/dev/${diskname1}"
    $diskdev2  = "/dev/${diskname2}"

    if "${diskdev1}X" !~ '^/dev/X' {
      notify { "Controller 0, target 0, disk 1: ${diskdev1}" : }
    }
    if "${diskdev2}X" !~ '^/dev/X' {
      notify { "Controller 0, target 0, disk 2: ${diskdev2}" : }
    }


    # create mountpoint
    file { [ "${mpdata}", "${mpbackup}", ]:
      ensure => directory,
    } ->
    if $facts['disks']["${diskname1}"] and $facts['disks']["${diskname2}"] {
      exec { 'pgsql_el9_datadevices-present':
        command  => '/bin/true',
        onlyif   => "test -h ${diskdev1} && test -h ${diskdev2}",
        unless   => "ls ${diskdev1} ${diskdev2} >/dev/null 2>&1",
        path     => ['/usr/bin','/usr/sbin','/bin','/sbin'],
        provider => 'shell',
      }

      if ! $facts['logical_volumes']["$lvdata"] {
        exec{"check_testdevs":
          command => "hdparm -z ${diskdev1} && hdparm -z ${diskdev2}",
          timeout  => 0,
          path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
          require => Exec['pgsql_el9_datadevices-present'],
        }
      }

      exec{'check_diskdevs':
        command  => "hdparm -z ${diskdev1} ${diskdev2}",
        timeout  => 0,
        unless   => "pvs ${diskdev1} ${diskdev2}",
        provider => 'shell',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      } ~>
      class { 'lvm':
        volume_groups => {
          "${vgname}" => {
            createonly => true,
            physical_volumes => [ "${diskdev1}", "${diskdev2}", ],
          },
        },
        require => [ Exec['check_diskdevs'],
                     File["${mpdata}"], File["${mpbackup}"], ],
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

    } elsif $facts['disks']["${diskname1}"] and ! $facts['disks']["${diskname2}"] {
      exec{"check_${diskdev1}":
        command  => "hdparm ${diskdev1}",
        timeout  => 0,
        unless   => "pvs ${diskdev1}",
        provider => 'shell',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      }
  
      class { 'lvm':
        volume_groups => {
          "${vgname}" => {
            createonly => true,
            physical_volumes => [ "${diskdev1}" ],
            logical_volumes  => {
              "${lvdata}"   => {
                'ensure'            => 'present',
                'size'              => "${szdata}",
                'fs_type'           => "${filesys}",
                'mountpath'         => "${mpdata}",
                'mountpath_require' => true,
              },
              "${lvbackup}"   => {
                'ensure'            => 'present',
                'size'              => "${szbackup}",
                'fs_type'           => "${filesys}",
                'mountpath'         => "${mpbackup}",
                'mountpath_require' => true,
              },
            },
          },
        },
        require => [ Exec["check_${diskdev1}"],
                     File["${mpdata}"], File["${mpbackup}"], ],
      } 

    } else {
      fail( "This role requires RHEL 9 or later with at least a second - and optional a third disk" )
    } 

    if ! defined(Package[postgresql-server]) and "${compvers}X" != "${pgrh9vers}X" {
      package { 'PostgreSQL dnf module':
        name        => 'postgresql',
        ensure      => "${pgrh9vers}",
        provider    => 'dnfmodule',
        enable_only => true
      }
    } 
    file { [ '/usr/local/bin/pg_backup.config', ]:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      content => template('linuxbeheerscripts/pg_backup.config.erb'),
    }

    file { [ '/usr/local/bin/pg_backup_rotated.sh', ]:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
      content => template('linuxbeheerscripts/pg_backup_rotated.sh.erb'),
    }

    file { [ '/etc/cron.d/postgres', ]:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      content => inline_epp($pgcrontab),
    }


  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
