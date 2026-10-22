################################################################################
#
# Bring parameters that are used in multiple modules in scope
#
################################################################################
class team_linux::profile::parameters {
  $git_docurl            = lookup({ name => 'team_linux::git_docurl', value_type => String, merge => 'deep', default_value => undef })
  $git_group             = lookup({ name => 'team_linux::git_group', value_type => String, merge => 'deep', default_value => undef })
  $smtp_relay            = lookup({ name => 'team_linux::smtp_relay', value_type => String, merge => 'deep', default_value => undef })
  $linuxbeheer_mail      = lookup({ name => 'team_linux::linuxbeheer_mail', value_type => String, merge => 'deep', default_value => undef })
  $tiso_mail             = lookup({ name => 'team_linux::tiso_mail', value_type => String, merge => 'deep', default_value => undef })
  $httpproxyserver       = lookup({ name => 'team_linux::usehttpproxyserver', value_type => String, merge => 'deep', default_value => 'proxylb.cak-bz.local:8080' })
  $usehttpproxyserver    = lookup({ name => 'team_linux::httpproxyserver', value_type => Boolean, merge => 'deep', default_value => false })
  #$netwerkbeheer_mail   = lookup({ name => 'team_linux::netwerkbeheer_mail', value_type => String, merge => 'deep', default_value => undef })
  #$netwerkbeheer_sender = lookup({ name => 'team_linux::netwerkbeheer_sender', value_type => String, merge => 'deep', default_value => undef })
  $hassplunkufw          = lookup({ name => 'splunkuniversalforwarder::hassplunkufw', value_type => Boolean, merge => 'deep', default_value => false })
  #$rhelmajor             = 0 + $facts['os']['release'][major]
  #$rhelminor             = 0 + $facts['os']['release'][minor]
  $rhelmajor             = Integer($facts['os']['release']['major'])
  $rhelminor             = Integer($facts['os']['release']['minor'])
  $osfamily              = $facts['os']['family']
  $operatingsystemmajrelease = $facts['os']['release']['major']
  $syslog_prog           = lookup({ name => 'team_linux::local0_filter', merge => 'deep', default_value => undef })

  # some default settings:
  $pgsqlvers = lookup({ name => 'team_linux::pgsqlvers', value_type => String, merge => 'first', default_value => '12'  })

  ##############################################################################
  # Direct AD communication and Puppet HBAC + sudo should be replaced by IPA
  ##############################################################################
  $joinad         = lookup({ name => 'team_linux::joinad', merge => 'first', default_value => false })
  $ipaclient      = lookup({ name => 'team_linux::ipaclient', merge => 'first', default_value => true })
  $ipa_domainname = lookup({ name => 'team_linux::ipa_domainname', merge => 'first', default_value => undef })
  $ad_domainname  = lookup({ name => 'team_linux::ad_domainname', merge => 'first', default_value => undef })

  ##############################################################################
  # Install proprietary stuff 
  ##############################################################################
  $taintedkernel = String($facts['tainted']).chomp()
  #$installdsa     = lookup({ name => 'team_linux::installdsa', merge => 'first', default_value => false }) # see profile instead

  ##############################################################################
  # establish a merged deep array of the hiera hierarchy of defined localserviceaccounts 
  # $localserviceaccounts  = lookup({name => 'team_linux::localserviceaccounts', merge => 'hash'})
  # After completing the IdM/IPA transition, this lookup can move to the top
  ##############################################################################
  # get the accountdata Hash, keyed by logname
  $allaccountdata = lookup({name => 'team_linux::accountdata',  merge => 'deep'})
  # Dirty solution to keep the service operational during transition form AD to IdM/IPA
  # Remove this case statement and the legacy.yaml file when done in 2038 or so :-(
  ##############################################################################
  # Remove this case statement and the legacy.yaml file when done in 2038 or so :-(
  if $joinad == true {
    $legacysvcaccounts     = lookup({name => 'team_linux::localserviceaccounts_legacy', merge => 'hash', default_value => undef })
    #notify {"Legacy: $legacysvcaccounts":}
    $othersvcaccounts      = lookup({name => 'team_linux::localserviceaccounts', merge => 'hash', default_value => undef })
    #notify {"Other-svc-accounts: $othersvcaccounts":}
    if defined('$legacysvcaccounts') and defined('$othersvcaccounts') {
      $localserviceaccounts = $legacysvcaccounts + $othersvcaccounts
    } elsif defined('$legacysvcaccounts') {
      $localserviceaccounts = $legacysvcaccounts
    } else {
      $localserviceaccounts = $othersvcaccounts
    }
    #notify {"Total =  Legacy + Others: $localserviceaccounts":}
    # following moved here from legacy profile localserviceaccount.pp 
    # Cleanup as soon as obsolete!
    $disabledaccounts = lookup({name => 'team_linux::accounts2delete', merge => 'hash', default_value => undef })
    #notify {"Disabled-accounts: $disabledaccounts":}
    if defined('$localserviceaccounts') and defined('$disabledaccounts') {
      $accounts_merge = $localserviceaccounts + $disabledaccounts
      #notify {"Total + Disabled accounts: $accounts_merge":}
    } elsif defined('$localserviceaccounts') {
      $accounts_merge = $localserviceaccounts
      #notify {"Total: $accounts_merge":}
    } else {
      $accounts_merge =  $disabledaccounts
      #notify {"Disabled only: $accounts_merge":}
    }
  } else {
    if $ipaclient == true or ( ! $ipaclient and ! $joinad ) {
      $localserviceaccounts  = lookup({name => 'team_linux::localserviceaccounts', merge => 'hash', default_value => undef })
      #notify {"IdM-serviceaccounts: $localserviceaccounts":}
    }
  }

  ##############################################################################
  # other conditional checks
  ##############################################################################
  $resolvcf  = lookup({ name => 'team_linux::resolveconf', merge => 'first', default_value => true })
  $mghostsf  = lookup({ name => 'team_linux::mghostsf', merge => 'first', default_value => true })

  ##############################################################################
  # Former HBAC parts of linuxaccess and/or other temporary HBAC implementation
  ##############################################################################
  # Maybe, root login can be disabled the moment there are alternatives
  $root_login = lookup({ name => 'team_linux::root_login', merge => 'first', default_value => true })
  # temporary implementation of: HBAC (SSH access), Sudo privileges, ..
  $linuxhbac = lookup({ name => 'team_linux::linuxhbac', value_type => String, merge => 'deep', default_value => 'pambased' })
  $admins = lookup({ name => 'team_linux::sudo_root', merge => 'unique', default_value => undef  })
  if $cmdb['role'] != undef {
    $fullnoderole = split($cmdb['role'], /::/)
    $noderole     = $fullnoderole[-1]
    $admin_team   = $fullnoderole[0]
    $admin_users  = lookup({ name => "team_linux::${admin_team}_members", merge => 'unique', default_value => undef })
  }
  $otherssh = lookup({ name => 'team_linux::ssh_access', merge => 'unique', default_value => undef  })
  if $admin_users != undef and $otherssh != undef {
    $mortals = unique($admin_users + $otherssh)
  } elsif defined('$admin_users') {
    $mortals = $admin_users
  } elsif defined('$otherssh') {
    $mortals = $otherssh
  } else {
    $mortals = undef
  }
  # The SSH-dummy group is not needed for PAM based acces (supports AD groups directly)
  # The following is needed during transition: local group with remote accounts!
  #   (needs module puppet_gpasswd!)
  # see team_linux::profile::ssh_dummygroup.pp
  $sshdummy = lookup({ name => 'team_linux::groups::sshdummy', default_value => 'sshdummy' })

  ##$mortals = lookup({ name => 'team_linux::ssh_access', merge => 'unique', default_value => undef  })
  # use values from parameters.pp for all users allowed to login using SSH
  # except for values unique to this profile:
  $systemacc = lookup({ name => 'team_linux::ssh_svcaccounts', merge => 'unique', default_value => undef  })

  if ( $admins != undef and $mortals != undef and $systemacc != undef ) {
    $ssh_users = unique( $admins + $mortals + $systemacc )
    # debug # notify{"SSH_users: $ssh_users":}
  } elsif ( $admins != undef and $mortals ) {
    $ssh_users = unique( $admins + $mortals )
    # debug # notify{"SSH_users: $ssh_users":}
  } elsif defined('$admins') != undef {
    $ssh_users = $admins 
    # debug # notify{"SSH_users: $ssh_users":}
  } else {
    fail("'team_linux::sudo_root', 'team_linux::ssh_access', and/or 'team_linux::ssh_svcaccounts' is undefined")
  }

  # transform the access_accounts array into a string suitable for sshd AllowUsers
  $ssh_users_join = join($ssh_users,' ')

  # SSH groups for PAM based access
  $ssh_grouplist = lookup({ name => 'team_linux::ssh_groups', merge => 'unique', default_value => undef })
  if $ssh_grouplist != undef {
    # transform the access_accounts array into a string suitable for access.conf
    $sshgroupbraces = $ssh_grouplist.map | $sshgroup | { "(${sshgroup})" }
    $pamssh_groups = join($sshgroupbraces,' ')
  }

  # Default is no SSH forwarding, but it is a requirement for DBA, ...
  $ssh_forwarding = lookup({ name => 'team_linux::ssh_forwarding', merge => 'deep', default_value => 'no' })

  ##############################################################################
  # various profiles
  ##############################################################################
  $appdisk             = 'sdb' # general purpose application disk
  $dockerdisk          = 'sdb' # disk used in Docker profiles RHEL 7

}
