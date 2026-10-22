################################################################################
# Implement role, set provisioning/state to ready, or log missing requirements
################################################################################
class team_linux::role::ipaserver inherits team_linux::profile::parameters {
  if ( $facts['role'] == undef or $facts['team'] == undef or $facts['repositories'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline
    contain team_linux::profile::ipaserver

    if $facts['osfamily'] == 'RedHat' and $rhelmajor >= 8 {

        Class['::team_linux::meta_profile::baseline'] ->
        Class['team_linux::profile::ipaserver']

    } else {
      fail( "This role requires RHEL 8 or later" )
    }
  }
}

