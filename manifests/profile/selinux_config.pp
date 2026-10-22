class team_linux::profile::selinux_config inherits team_linux::profile::parameters {
  if $rhelmajor > 7 {
    #$selinuxconf = lookup({ name => 'team_linux::selinuxconf', value_type => String, merge => 'first', default_value => 'enforcing'  })
    $selinuxconf = lookup({ name => 'team_linux::selinuxconf' })
    if $selinuxconf != 'disabled' {
      # To do: configure /etc/selinux/config
      exec{'immutable_selinux_config':
        command  => 'chattr +i /etc/selinux/config',
        timeout  => 0,
        unless   => '/usr/bin/lsattr /etc/selinux/config | /usr/bin/grep -E "^^.{4}i" -q',
        onlyif   => 'grep -Ei "^SELINUX=enforcing" /etc/selinux/config >/dev/null',
        provider => 'shell',
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      }
    } else {
      $selinuxconf = lookup({ name => 'team_linux::selinuxconf', value_type => String, merge => 'first', default_value => 'disabled'  })
    }
  }
}

