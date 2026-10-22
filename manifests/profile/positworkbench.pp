class team_linux::profile::positworkbench inherits team_linux::profile::parameters {

  $positdata = lookup({ name => 'team_linux::positdata', merge => 'first', default_value => '/dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:2:0' })
  $mpowner = lookup({ name => 'team_linux::positwbuser:', merge => 'first', default_value => 'posit' })
  $mpgroup = lookup({ name => 'team_linux::positwbgroup', merge => 'first', default_value => 'pg-mg-posit-users@ipaprod.hetcak.nl' })

  if $positdata != undef {
    $vgname  = 'positwb-vg'
    $lvdata  = 'positwb-data'
    $lvlog   = 'positwb-log'
    $filesys = 'xfs'
    $mpmode  = '0750'
    $szdata  = lookup({ name => 'team_linux::szpositwbdata', merge => 'unique', default_value => '50G'  })
    $mpdata  = lookup({ name => 'team_linux::positwbmp', default_value => "/opt/${mpowner}" })
    $szlog   = lookup({ name => 'team_linux::szpositwblog', merge => 'unique', default_value => '5G'  })
    $mplog   = lookup({ name => 'team_linux::positlogmp', default_value => "/var/log/${mpowner}" })

#    # create NFS-mountpoint - <- see 'netmounts.pp' <- not working!
#    file { [ "/media/${mpowner}", ]:
#      ensure  => directory,
#      owner   => $mpowner,
#      group   => $mpgroup,
#      mode    => $mpmode,
#    } 

# /opt i.p.v. /opt/posit, dus nog een kip-of-ei-probleem
#    exec { 'positdata-present':
#      command => '/bin/true',
#      onlyif  => "test -h ${positdata}",
#      path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
#    }
#
#    if ! $facts['logical_volumes']["$lvdata"] {
#      exec{"check_${positdata}":
#        command => "hdparm ${positdata}",
#        timeout  => 0,
#        path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#        require => Exec['positdata-present'],
#      }
#    } 
#
#    $pvname = "lvm_vg_${vgname}_pvs"
#    if $vgname in $facts['volume_groups'] {
#      if ',' in $facts["${pvname}"] {
#        fail ("More than one physical volume in volumegroup not supportet for this role!" )
#      } else {
#        $physv = $facts["${pvname}"] 
#      }
#    } else {
#      $physv = [ "${positdata}", ]
#    }
#
#
#    # create mountpoint
#    file { [ "${mpdata}", "${mplog}", ]:
#      ensure  => directory,
#      owner   => $mpowner,
#      group   => $mpgroup,
#      mode    => $mpmode,
#      require => Exec['positdata-present'],
#    } ->
#    lvm::volume { "${lvdata}":
#      ensure  => present,
#      pv      => "${physv}",
#      vg      => "${vgname}",
#      fstype  => "${filesys}",
#      size    => "${szdata}",
#      require => [ Exec['positdata-present'], ],
#    } ->
#    # Now add normal mount (i.e. not proviced via lvm module):
#    mount{ "${mpdata}":
#      name    => "${mpdata}",
#      device  => "/dev/${vgname}/${lvdata}",
#      fstype  => "${filesys}",
#      ensure  => mounted,
#      require => Exec['positdata-present'],
#    } ->
#    lvm::volume { "${lvlog}":
#      ensure  => present,
#      pv      => "${physv}",
#      vg      => "${vgname}",
#      fstype  => "${filesys}",
#      size    => "${szlog}",
#      require => [ Exec['positdata-present'], ],
#    } ->
#    # Now add normal mount (i.e. not proviced via lvm module):
#    mount{ "${mplog}":
#      name    => "${mplog}",
#      device  => "/dev/${vgname}/${lvlog}",
#      fstype  => "${filesys}",
#      ensure  => mounted,
#      require => Exec['positdata-present'],
#    } 

    if $facts['os']['selinux'] {
      exec { 'init_t':
        command  => 'semanage permissive -a init_t',
        provider => 'shell',
        unless   => 'semanage permissive -l |grep init_t',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      }
    }

  file{ '/etc/logrotate.d/positworkbench':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    =>  '0640',
    content => template('team_linux/logrotate_positwb.erb'),
  }

#  # correct Deep Shit misconduct - https://access.redhat.com/solutions/7109596
#  exec {'fix_utab.event_permissions':
#    command  => 'chmod 0644 /run/mount/utab.event && chown root:root /run/mount/utab.event',
#    onlyif   => 'test -f /run/mount/utab.event',
#    unless   => "[[ $(/usr/bin/stat --format '%a' /run/mount/utab.event) -eq 644 ]]",
#    provider => 'shell',
#    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
#  }

  } else {
    fail ( "No disk for positdata found" )
  }

  exec {'mount_posit':
    command => 'mount /media/posit',
    onlyif   => "[[ $(stat -f -c '%T' /media/posit) = xfs ]]",
    provider => 'shell',
    path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
  } 

}
