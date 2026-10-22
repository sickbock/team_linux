###############################################################################
# IPA specific classes, profiles an dependency orderin
###############################################################################
class team_linux::meta_profile::baseline_ipa inherits team_linux::profile::parameters {
  # before this clase, contain some stuf like
 
  # contain team_linux::profile::selinuxhomedirs
  # contain team_linux::profile::remove_unused_rhel7_services
  # contain team_linux::profile::remove_inactive_services
  # contain linuxbeheerscripts

  if $ipaclient == true or $noderole == "ipaserver" {
    #contain ipajoin
    contain team_linux::profile::removelegacyuser
    if $noderole != "ipaserver" {
      class {'::ipajoin':
        ipa_join_password => lookup({ name => 'team_linux::ipa_join_password', merge => 'first', default_value => undef })
      }
    }

    contain team_linux::profile::localaccount
    contain team_linux::profile::systemuserpubkeys
    contain team_linux::profile::systemusersudo

    if $noderole != "ipaserver" {
      Class['team_linux::profile::localaccount'] ->
      Class['ipajoin']

      Class['ipajoin'] ->
      Class['team_linux::profile::opt_user_homedisk'] 
    }

    Class['team_linux::profile::localaccount'] ->
    Class['team_linux::profile::systemuserpubkeys']

    Class['team_linux::profile::localaccount'] ->
    Class['team_linux::profile::systemusersudo']

  }
}
