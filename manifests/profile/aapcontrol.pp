################################################################################
# Prepare RHEL 8 system voor Ansible Automation platform controller installation
#   2.0.1 requires Ansible engine 2.11 + subscriptions available from Satellite
#      second disk needed for /var/lib/awx 
################################################################################
class team_linux::profile::aapcontrol inherits team_linux::profile::parameters {
 
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {

    $diskdev   = "/dev/${appdisk}"
    $vgname    = 'aapcontrol-vg'
    $lvengine  = 'engine-data'
    $lvbackup  = 'lv-backup'
    $lvdata    = 'aapcontrol-data'
    $filesys   = 'xfs'
    $szawx    = lookup({ name => 'team_linux::szawxdata', merge => 'unique', default_value => '20G'  })
    $szaapbck = lookup({ name => 'team_linux::szaapbck', merge => 'unique', default_value => '60G'  })
    $mpawx    = '/var/lib/awx'
    $backup   = '/var/backups'
    $mpbackup = '/var/backups/automation-platform'

    exec{"check_${diskdev}":
      command => "hdparm ${diskdev}",
      timeout  => 0,
      unless => "grep ready /var/lib/provisioning/state",
      path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    }

    # create mountpoint
    file { [ "${mpawx}", "${backup}", "${mpbackup}", ]:
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
              'size'              => "${szawx}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mpawx}",
              'mountpath_require' => true,
            },
            "${lvbackup}"   => {
              'ensure'            => 'present',
              'size'              => "${szaapbck}",
              'fs_type'           => "${filesys}",
              'mountpath'         => "${mpbackup}",
              'mountpath_require' => true,
            },
          },
        },
      },
      require => [ Exec["check_${diskdev}"],
                   File["${mpawx}"], File["${backup}"], File["${mpbackup}"], ],
    } 

  } else {
      notice("${osfamily}: Unsupported operating system or ${operatingsystemmajrelease}: Unsupported release")
  }

}
