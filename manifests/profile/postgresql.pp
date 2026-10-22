################################################################################
# PostgreSQL database server on RHEL 8
# workaround missing dnf module support in Puppet 5 using 'exec' 
#   note: workaroune and tests are not optimal & require multiple Puppet runs
################################################################################
class team_linux::profile::postgresql inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    # see parameters # $pgsqlvers = lookup({ name => 'team_linux::pgsqlvers', value_type => String, merge => 'first', default_value => undef  })
    $backupusr = lookup({ name => 'team_linux::pgsqlbackupusr', value_type => String, merge => 'first', default_value => 'root'  })
    $dbuser = lookup({ name => 'team_linux::pgsqldbuser', value_type => String, merge => 'first', default_value => 'postgres'  })
    $pgcrontab = lookup({ name => 'team_linux::pgsqlcrontab', value_type => String, merge => 'first', default_value => "33 03 * * * root /usr/local/bin/pg_backup_rotated.sh >/var/log/pgbackup.log 2>&1\n"  }) # add explicit newline, otherwise cron ignors the line entirely
    $diskdev1  = '/dev/sdb'
    $diskdev2  = '/dev/sdc'
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

    # create mountpoint
    file { [ "${mpdata}", "${mpbackup}", ]:
      ensure => directory,
    } ->
    if $facts['disks']['sdb'] and $facts['disks']['sdc'] {

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

    } elsif $facts['disks']['sdb'] and ! $facts['disks']['sdc'] {
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
      fail( "This role requires RHEL 8 or later with at least one disk 'sdb' or two disk 'sdb' and 'sdc'" )
    } 
#    # Enable the PostgreSQL $pgsqlvers stream on RHEL 8
#    # Still no documented support for dnf:
#    # https://tickets.puppetlabs.com/browse/PUP-10235
#    # Otherwise the puppetlabs-postgresql module just installs the the default
#    # or tries to use the Puppet dnf provider, ... just to be safe
#    # we prefer to make sure to enable the correct module version first
#    # But, don't change anything if postgres
#    #notify { "fact: ${facts['postgresmodule']}X":}
#    #notify { "String converted fact: ${compvers}Y":}
#    #notify { "string: ${pgsqlvers}Z":}
#    #if ! $facts['postgresmodule'] or "${compvers}*" !~ "${pgsqlvers}*" {
#    #notify { "Comparison: ${compvers}X != ${pgsqlvers}X": }
#    if "${compvers}X" != "${pgsqlvers}X" {
#      exec { 'enable_postgresql_module':
#        command  => "dnf -y module reset postgresql; dnf -y module enable postgresql:${pgsqlvers}; dnf -y distro-sync",
#        provider => 'shell',
#        unless   => 'test -x /usr/bin/postgres',
#        onlyif   => "egrep ${mpdata}'[  ]' /proc/mounts",
#        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#      }
#    }
    if ! defined(Package[postgresql-server]) and "${compvers}X" != "${pgsqlvers}X" {
      package { 'PostgreSQL dnf module':
        name        => 'postgresql',
        ensure      => "${pgsqlvers}",
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
