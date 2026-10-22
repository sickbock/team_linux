################################################################################
# Prepare RHEL 8 system voor Ansible Automation platform hub installation
#   2.0.1 requires Ansible engine 2.11 + subscriptions available from Satellite
#      second disk needed for /var/lib/pulp 
################################################################################
class team_linux::profile::aaphub inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    $diskdev   = "/dev/${appdisk}"
    $vgname    = 'aaphub-vg'
    $lvengine  = 'pulp-data'
    $lvdata    = 'aaphub-data'
    $lvbackup  = 'aaphub-backup'
    $filesys   = 'xfs'
    $szpulp    = lookup({ name => 'team_linux::szpulpdata', merge => 'unique', default_value => '50G'  })
    $szhbackup = lookup({ name => 'team_linux::szhubbackup', merge => 'unique', default_value => '20G'  })
    $mppulp    = '/var/lib/pulp'
    $mphbackup = '/var/backups/automation-platform'

    exec{"check_${diskdev}":
      command => "hdparm ${diskdev}",
      timeout  => 0,
      unless => "grep ready /var/lib/provisioning/state",
      path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    }

    # create mountpoint
    file { [ "${mppulp}", "${mphbackup}", ]:
      ensure => directory,
    }

    class { 'lvm':
      volume_groups => {
        "${vgname}" => {
          createonly => true,
          physical_volumes => [ "${diskdev}" ],
          logical_volumes  => {
            "${lvengine}"   => {
              'ensure'            => 'present',
              'size'              => "${szpulp}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mppulp}",
              'mountpath_require' => true,
            },
            "${lvbackup}" => {
              'ensure'            => 'present',
              'size'              => "${szhbackup}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mphbackup}",
              'mountpath_require' => true,
            },
          },
        },
      },
      require => [ Exec["check_${diskdev}"],
                   File["${mppulp}"], File["${mphbackup}"], ],
    } 

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
