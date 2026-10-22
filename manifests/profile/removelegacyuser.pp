################################################################################
# Former local accounts that should be removed (i.e. because the are in IdM/IPA)
################################################################################
class team_linux::profile::removelegacyuser inherits team_linux::profile::parameters {

  $legacyusers = lookup({ name => 'team_linux::localserviceaccounts_legacy', default_value => '/etc/ssh/authorized_keys' })
  if defined('$legacyusers') {
    $legacylocals          = keys($legacyusers)
  }

  ##################################################
  # Remove account that should not exist locally
  ##################################################
  if defined('$legacylocals') {
    $legacylocals.each | $l_logname | {
      if defined('$l_logname') {
        exec {"userdel_${l_logname}":
          command  => "userdel -r ${l_logname}",
          onlyif   => "grep ${l_logname} /etc/passwd",
          path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        }~>
        exec {"rmhomedir_${l_logname}":
          command     => "rm -rf /home/${l_logname}",
          refreshonly => true,
          path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        }
      }
    }
  }
}
