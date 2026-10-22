class team_linux::profile::sysctl {
  contain sysctl

  $sysctl = lookup({ name => "team_linux::sysctl",  merge => 'deep'  })

  $sysctl.each | $key, $value | {
    if $key !~ "shmmax" and $key !~ "shmall" {
      sysctl{ "${key}": ensure => present, permanent => 'yes', value => "${value}" }
    }
  }

}
