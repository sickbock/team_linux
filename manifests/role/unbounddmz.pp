################################################################################
# Implement role, set provisioning/state to ready, or log missing requirements
################################################################################
class team_linux::role::unbounddmz inherits team_linux::profile::parameters {
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline
    contain ::unbound

    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 8 {
        class { '::team_linux::profile::provisioning_ready':
          require => [
            File['/etc/resolv.conf'],
            File['/etc/motd'],
            File['/etc/profile.d/commonprofile.sh'],
          ],
        }

        Class['::team_linux::meta_profile::baseline'] ->
        Class['::unbound']

    } else {
      fail( "This role requires RHEL 8 or later" )
    }
  }
}

