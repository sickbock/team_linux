class team_linux::profile::netmounts {
  # manage netmounts
  $cifs_usr = lookup({name => 'team_linux::cifs_usr', merge => 'deep', default_value => undef })
  $cifs_pw = lookup({name => 'team_linux::cifs_pw', merge => 'deep', default_value => undef })
  $cifs_dom = lookup({name => 'team_linux::cifs_dom', merge => 'deep', default_value => undef })
  $wmo2020nfs  = lookup({name => 'team_linux::wmo2020nfs', default_value => undef })
  $nfs_mounts = lookup({name => 'team_linux::profile::netmounts', merge => 'hash', default_value => undef })
  if $nfs_mounts != undef {
    $nfs_mountpoints=$nfs_mounts['mountpoints']
    $nfs_mountpoint_owner=$nfs_mounts['owner']
    $nfs_mountpoint_group=$nfs_mounts['group']
    $nfs_mountpoint_mode=$nfs_mounts['mode']
    $nfs_mountpoint_mounts=$nfs_mounts['mounts']
    if $nfs_mountpoints != undef and
       $nfs_mountpoint_owner != undef and
       $nfs_mountpoint_group != undef and
       $nfs_mountpoint_mode != undef and
       $nfs_mountpoint_mounts != undef {
      $nfs_mountpoints.each | $dir | {
#        if $wmo2020nfs == 'forcemp' {
#          file { [ "create_${dir}", ]:
#            name    => ${dir},
#            ensure => directory,
#            owner  => "${nfs_mountpoint_owner}",
#            group  => "${nfs_mountpoint_group}",
#            mode   => "${nfs_mountpoint_mode}",
#          }
#        } else {
          exec{ "create_mountpoint_${dir}":
            command => "mkdir -p ${dir} && chown ${nfs_mountpoint_owner}:${nfs_mountpoint_group} ${dir} && chmod ${nfs_mountpoint_mode} ${dir}",
            onlyif => "test ! -d ${dir}",
            path => '/bin:/usr/bin',
            provider => 'shell',
          }
#        }
      }
      keys($nfs_mountpoint_mounts).each | $mp | {
        if $nfs_mountpoint_mounts[$mp]['fstype'] == 'cifs' {
          if !defined(Package[cifs-utils]) {
            package{ "cifs-utils":
              ensure => installed,
            }
          }
          if !defined(File['/root/cifs.cred']) {
            file{ '/root/cifs.cred':
              owner   => 'root',
              group   => 'root',
              mode    => '0600',
              content => template('team_linux/cifs.cred.erb'),
            }
          } 
        }
        if $nfs_mountpoint_mounts[$mp]['fstype'] == 'nfs' {
          if !defined(Package[nfs-utils]) {
            package{ 'nfs-utils':
              ensure => installed,
            }
          }

          # Following doesn't seem to work, possible relation with socket?
          if !defined(Package[rpcbind]) {
            #notify { "Package rpcbind is installed" :}
            package{ 'rpcbind':
              ensure => installed,
            }
          }
          if ! defined(Service['rpcbind']) {
            #notify { "Configuring service rpcbind" :}
            service{ 'rpcbind':
              ensure => running,
              enable => true,
            }
          }
        }
        if $wmo2020nfs == 'forcemp' {
          if $nfs_mountpoint_mounts[$mp]['fstype'] == 'nfs' {
            # Test: # notify{"Paramteter wmo2020nfs set to: $wmo2020nfs":}
             file { [ "${mp}", ]:
               name   => "${mp}",
               ensure => directory,
               owner  => "${nfs_mountpoint_owner}",
               group  => "${nfs_mountpoint_group}",
               mode   => "${nfs_mountpoint_mode}",
             }
             mount{ "${mp}":
               name    => "${mp}",
               device  => "${nfs_mountpoint_mounts[$mp]['device']}",
               ensure  => "${nfs_mountpoint_mounts[$mp]['ensure']}",
               options => "${nfs_mountpoint_mounts[$mp]['options']}",
               fstype  => "${nfs_mountpoint_mounts[$mp]['fstype']}",
               require => File["${mp}"],
               #notify  => File["post_${mp}"],
             }
             exec{"enforce_${mp}_ownergroupmod":
               command => "chown ${nfs_mountpoint_owner}:${nfs_mountpoint_group} ${mp}; chmod ${nfs_mountpoint_mode} ${mp}",
               timeout => 0,
               onlyif => "egrep ${mp}.*nfs /proc/mounts >/dev/null 2>&1", 
               # mountpoint owner can only be changed during second Puppet run, so do it now or expect failures
               unless  => "stat --format '%U:%g' ${mp} |grep ${nfs_mountpoint_owner}:${nfs_mountpoint_group} >/dev/null 2>&1",
               # Read only op server? then this action will be executed every run!
               #onlyif  => "[ $(stat --format '%U:%g' ${mp}) != ${nfs_mountpoint_owner}:${nfs_mountpoint_group} ]",
               #onlyif => "grep -v '^ready$' /var/lib/provisioning/state",
               path    => [ '/bin', '/usr/bin', '/sbin' ],
               require => Mount["${mp}"],
               provider => 'shell',
             }
             exec{"enforce_${mp}_subdirs_ownergroupmod":
               command => "find ${mp} -type d -exec chown ${nfs_mountpoint_owner}:${nfs_mountpoint_group} {} \; ; find ${mp}/* -type d -exec chmod ${nfs_mountpoint_mode} -prune {} \;",
               timeout => 0,
               # ugly workaround for sane design: change dirs under mountpoint 
               unless  => "stat --format '%U:%g' ${mp}/* |grep ${nfs_mountpoint_owner}:${nfs_mountpoint_group} >/dev/null 2>&1",
               #onlyif => "grep -v '^ready$' /var/lib/provisioning/state",
               onlyif  => "ls ${mp}/* > /dev/null 2>&1 && egrep ${mp}.*nfs /proc/mounts >/dev/null 2>&1",
               path    => [ '/bin', '/usr/bin', '/sbin' ],
               require => Mount["${mp}"],
               provider => 'shell',
             }
  
             #file { [ "post_${mp}", ]:
             #  path   => "${mp}",
             #  ensure => directory,
             #  owner  => "${nfs_mountpoint_owner}",
             #  group  => "${nfs_mountpoint_group}",
             #  mode   => "${nfs_mountpoint_mode}",
             #}
           }
        } else {
          # Test: # notify{"Paramteter wmo2020nfs not set or set to: $wmo2020nfs":}
          mount{ "${mp}":
            name => "${mp}",
            device => "${nfs_mountpoint_mounts[$mp]['device']}",
            ensure => "${nfs_mountpoint_mounts[$mp]['ensure']}",
            options => "${nfs_mountpoint_mounts[$mp]['options']}",
            fstype => "${nfs_mountpoint_mounts[$mp]['fstype']}",
          }
        }
      }
    } else {
     fail( "definition incomplete, either mountpoints, owner, group, mode or mounts variable missing. see netmount profile docs in git" )
    }
  }
}
