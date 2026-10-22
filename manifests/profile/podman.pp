class team_linux::profile::podman inherits team_linux::profile::parameters {
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '9' ) {

    if ! defined(Package[git]) {
      package { 'Install git for container tools':
        name        => 'git',
        ensure      => present,
      }
    }
    if ! defined(Package[container-tool]) {
      package { 'Install container tools':
        name        => 'container-tools',
        ensure      => present,
      }
    } ->
    if ! defined(Package[podman-docker]) {
      package { 'Install podman-docker for container tools':
        name        => 'podman-docker',
        ensure      => present,
      }
    } 
    if ( $facts['volume_groups']['rhel']['free'] > '0' ) {
      exec {'podman_extend_rhel/home':
        command     => 'lvextend -r  -l +100%FREE rhel/home',
        path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        onlyif      => 'test $( /usr/sbin/lvs rhel/home --noheadings --units m -o lv_size|cut -d. -f1) -le 4096',
      }
    }   
  }
}
