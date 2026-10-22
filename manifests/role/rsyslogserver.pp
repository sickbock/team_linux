################################################################################
# Implement role, set provisioning/state to ready, or log missing requirements
################################################################################
class team_linux::role::rsyslogserver inherits team_linux::profile::parameters { 
  if ( $facts['role'] == undef or $facts['team'] == undef ) {
    contain team_linux::profile::external_facts
  } else {
    require team_linux::meta_profile::baseline
    contain team_linux::profile::rsyslogserver

    if $facts['os']['family'] == 'redhat' and $rhelmajor >= 8 {
      if $facts['disks']['sdb'] and $facts['disks']['sdc'] {

        class { '::team_linux::profile::provisioning_ready':
          subscribe => [
            Mount['/var/log/remote'],
          ],
        }

        Class['::team_linux::meta_profile::baseline'] ->
        Class['team_linux::profile::rsyslogserver']

        Class['team_linux::profile::rsyslogserver'] ->
        Class['::team_linux::profile::provisioning_ready']

      } else {
        # one or more prerequisites failed, log
        if ! $facts['disks']['sdb'] or ! $facts['disks']['sdc'] { notify{ "Data disk(s) sdb and/or sdc  not found, skipping install of $cmdb['role']": } }
        exec{ "provisioning_failed_prereqs":
          command => "echo 'install_wait' > /var/lib/provisioning/state",
          path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        }
      }
    } else {
      fail( "This role requires RHEL 8 or later" )
    }

  }

}

