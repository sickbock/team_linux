class team_linux::profile::oddjob_mkhomedir inherits team_linux::profile::parameters {
  #notify {"B4 - IPA: $ipaclient AD: $joinad Role: $noderole" : }
  if ( $ipaclient == false and $joinad == false ) or $noderole == 'ipaserver' {
    #notify {"IPA: $ipaclient AD: $joinad Role: $noderole" : }
    if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] < '8' ) {
      exec {'standalone_oddjob_mkhomedir7':
        command => '/usr/sbin/authconfig --enablesssd --enablesssdauth --enablemkhomedir --update',
        onlyif  => '/usr/sbin/authconfig --test|/bin/egrep "mkhomedir is disabled"'
      }
    }
    else {
      exec {'standalone_oddjob_mkhomedir8':
        command => '/usr/bin/authselect select sssd with-mkhomedir --force; /bin/systemctl restart oddjobd',
        unless  => '/usr/bin/grep pam_oddjob_mkhomedir /etc/pam.d/* >/dev/null 2>&1' ,
      }
    }
  }
}
