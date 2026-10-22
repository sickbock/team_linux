################################################################################
# Manage PAM access in case that is preferred over SSH HBAC 
# see parameter $linuxhbac and sshd_config.pp also
#     
# Note: As soon as HBAC is implemented using host groups and SSSD 
#   SSH configuration can be re-integrated in adjoin
################################################################################
class team_linux::profile::pam_access inherits team_linux::profile::parameters {

  #$denyusers = lookup({name => 'team_linux::pam_deny_access', value_type => String, merge => 'first', default_value => 'admin user factory USERID userid zyfwp' })

  if defined('$linuxhbac') == 'pambased' {

    if !defined(Package['pam']) {
      package{ 'pam':
        ensure => installed,
      }
    }

    file{ '/etc/security/access.conf':
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template(
        'team_linux/pam_access.conf.erb'
      ),
      require => Package['pam'],
    }

    file{ '/etc/pam.d/sshd':
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template(
        'team_linux/pam_sshd.erb'
      ),
      require => Package['pam'],
    }

  }

}
