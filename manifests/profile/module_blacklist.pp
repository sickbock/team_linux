class team_linux::profile::module_blacklist inherits team_linux::profile::parameters {

  # read in the module blacklist
  $blacklist = lookup({ name => "team_linux::module_blacklist",  merge => 'deep'  })


  # construct an array of all modules with ensure == undef or ensure = absent
  $black_array = reject( $blacklist.map | $key,$value | {
    if $blacklist["$key"] == undef or $blacklist["$key"]['ensure'] == 'absent' {
      "$key"
    }
  }, 'undef' )

  # remove floppy special (with typo)
  file{ '/etc/modprobe.d/blakclist-floppy.conf':
    ensure  => absent,
  }

  # all blacklisted modules
  file{ '/etc/modprobe.d/cak-blacklist.conf':
    ensure  => present,
    owner => root,
    group => root,
    mode  => '0600',
    content => template( 'team_linux/module_blacklist.conf.erb' ),
  }

  # disable floppy driver everywhere it is seen
  exec{ "rmmod_floppy":
    command   => "rmmod floppy",
    path      => [ '/bin', '/usr/bin', '/sbin' ],
    onlyif    => "lsmod | grep '^floppy'",
  }
}
