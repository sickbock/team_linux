################################################################################
# Limited (disk only) configuration to prepare system for Anypoint installation
################################################################################
class team_linux::profile::anypoint_rtf inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '7' ) {

    $diskdev   = "/dev/${appdisk}"
    $vgname    = 'anypoint_rtf'
    $lvdata    = 'anypoint_rtf_data'
    $lvtmp     = 'anypoint_rtf_tmp'
    $lvlog     = 'anypoint_rtf_log'
    $filesys   = 'xfs'
    $szdata    = lookup({ name => 'team_linux::szartf_data', merge => 'unique', default_value => '10G'  })
    $sztmp     = lookup({ name => 'team_linux::szartf_tmp', merge => 'unique', default_value => '20G'  })
    $szlog     = lookup({ name => 'team_linux::szartf_log', merge => 'unique', default_value => '10G'  })
    $mpoints   = '/opt/anypoint'
    $mpdata    = '/opt/anypoint/runtimefabric'
    $mptmp     = '/opt/anypoint/tmp'
    $mplog     = '/opt/anypoint/log'


    exec{"check_${diskdev}":
      command  => 'true',
      timeout  => 0,
      unless   => "lsblk ${diskdev} >/dev/null 2>&1 || hdparm ${diskdev}",
      path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    }

    file { [ "${mpoints}", "${mpdata}", "${mptmp}", "${mplog}", ]:
      ensure => directory,
      owner  => 'rtfuser',
      group  => 'rtfuser',
      mode   => '0755'
    }

    class { 'lvm':
      volume_groups => {
        "${vgname}" => {
          createonly => true,
          physical_volumes => [ "${diskdev}" ],
          logical_volumes  => {
            "${lvdata}"   => {
              'ensure'            => 'present',
              'size'              => "${szdata}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mpdata}",
              'mountpath_require' => true,
            },
            "${lvtmp}"   => {
              'ensure'            => 'present',
              'size'              => "${sztmp}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mptmp}",
              'mountpath_require' => true,
            },
            "${lvlog}"   => {
              'ensure'            => 'present',
              'size'              => "${szlog}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mplog}",
              'mountpath_require' => true,
            },
          },
        },
      },
      require => Exec["check_${diskdev}"],
    }


  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
