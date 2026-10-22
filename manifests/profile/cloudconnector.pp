class team_linux::profile::cloudconnector inherits team_linux::profile::parameters {

  $serviceacc    = lookup({name => 'team_linux::cloudconusr', default_value => 'opentunnel'})
  $servicegrp    = lookup({name => 'team_linux::cloudcongrp', default_value => 'opentunnel'})
  $datafs        = lookup({name => 'team_linux::cloudcondata', default_value => '/opt/cloudconnector'})
  $szdata        = lookup({name => 'team_linux::cloudcondsze', default_value => '10G'})
  $logfs         = lookup({name => 'team_linux::cloudconlogf', default_value => '/var/log/cloudconnector'})
  $szlogfs       = lookup({name => 'team_linux::cloudconlsze', default_value => '10G'})
  $satellite     = lookup({name => 'team_linux::satellite_server', default_value => 'satellite.cak-bz.local' })
  $download_base = lookup({name => 'team_linux::download_base', default_value => 'pub' })
  $jnet_base     = lookup({name => 'team_linux::jnet_base', default_value => 'opentunnel_source' })
  $jnetcnpkgs    = lookup({name => 'team_linux::jnet_cloudcon_pkgs', merge => 'hash', default_value => undef })
  $jn_cloud_svc  = lookup({name => 'team_linux::jnet_cloudcon_svc', default_value => undef })

  $diskdev  = '/dev/sdb'
  $vgname   = 'opentunnel'
  $lvdata   = 'opentunnel_data'
  $lvlog    = 'opentunnel_log'
  $filesys  = 'ext4'

#  file { [ "${datafs}", "${logfs}", ]:
#    owner => "${serviceacc}",
#    group => "${servicegrp}",
#    mode  => "0750",
#  }

#  class { 'lvm':
#    volume_groups => {
#      "${vgname}" => {
#        createonly => true,
#        physical_volumes => [ "${diskdev}" ],
#        logical_volumes  => {
#          "${lvdata}"   => {
#            'ensure'            => 'present',
#            'size'              => "${szdata}",
#            'fs_type'           => "${filesys}",
#            'mountpath'         => "${datafs}",
#            'mountpath_require' => true,
#          },
#          "${lvlog}"    => {
#            'ensure'            => 'present',
#            'size'              => "${szlogfs}",
#            'fs_type'           => "${filesys}",
#            'mountpath'         => "${logfs}",
#            'mountpath_require' => true,
#          },
#        },
#      },
#    },
#    require => [ File["${datafs}"], File["${logfs}"], ]
#  }

#  # If you change the role, it might be wrong and therefore $jnetcnpkgs may be undefined
#  if $jnetcnpkgs != undef {
#    # following requires hash 'jnetcnpkgs' with package (rpm) name and installed file to check ('isinstalled')
#    # contains at least the cloudconnetor rpm name and systemd unit file installed by that package
#    $jnetcnpkgs.each |$artefact, $installedpkg | {
#      #notify{"Processing ${artefact} for ${installedpkg}":}
#      $pkgpath = $jnetcnpkgs[$artefact]['isinstalled']
#      #notify{"path is ${pkgpath}":}
#      #notify{"/bin/yum -y install https://${satellite}/${download_base}/${jnet_base}/${artefact}":}
#      exec {"install_${artefact}":
#        command   => "/bin/yum -y install https://${satellite}/${download_base}/${jnet_base}/${artefact}",
#        logoutput => true,
#        path => [ '/sbin', '/bin', '/usr/bin' ],
#        creates   => "${pkgpath}",
#        require => [ Mount["${datafs}"], Mount["${logfs}"], ],
#      }
#    }
#  } else {
#    notice("Parameter jnetcnpkgs is undefined or role is wrong!")
#  }

#  exec {"check_${jn_cloud_svc}":
#    command   => '/bin/true',
#    path      => ['/usr/bin','/usr/sbin','/bin','/sbin'],
#    unless    => "rpm -qf ${jn_cloud_svc}",
#    loglevel  => 'info',
#    logoutput => 'on_failure',
#  } # TAB should manage state, otherwise only start at boot (when systemd unit file is installed using hash $jnetcnpkgs):
#  -> service { "cloudconnector":
#    # only start at boot, TAB should manually start/stop during maintenance!
#    enable  => true,
#    require => [ Exec["check_${jn_cloud_svc}"],
#                 Mount["${datafs}"], Mount["${logfs}"], ],
#  }

}
