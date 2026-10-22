###############################################################################
# AD specific classes, profiles an dependency ordering
###############################################################################
class team_linux::meta_profile::baseline_ad inherits team_linux::profile::parameters {
  #notify { "AD: $joinad, IPA: $ipaclient" : }
  if $joinad == true and ! $ipaclient {
    #notify { "joining AD" : }
    # b4 IPA: use pam_access
    contain team_linux::profile::pam_access
    contain adjoin
  
    contain team_linux::profile::ssh_dummygroup
    contain team_linux::profile::sudo 
    contain team_linux::profile::localgroup
    contain team_linux::profile::localserviceaccount
  
    contain team_linux::profile::sudo_remote_group 

    # b4 IPA: use legacy SSH-group and key distribution:
    # new requirement "ansible_beheer" local user  # contain team_linux::profile::ssh_dummygroup
    contain team_linux::profile::sshpublickeys

    # this uggly legacy removal mess needs to go some day .... 
    # New requirement: sshdummy needs to exist always as long as there is no real central HBAC!
    Class['team_linux::profile::ssh_dummygroup'] ->
    Class['team_linux::profile::localserviceaccount']

    Class['team_linux::profile::localgroup'] ->
    Class['team_linux::profile::localserviceaccount']

    Class['team_linux::profile::localserviceaccount'] ->
    Class['adjoin']

    Class['team_linux::profile::pam_access'] ->
    Class['adjoin']

    Class['adjoin'] ->
    Class['team_linux::profile::sshpublickeys']

  }

}
