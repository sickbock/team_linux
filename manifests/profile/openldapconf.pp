################################################################################
# Nice to have: profile to manage privat CA's in the certificate store ...
# for now, just assume IPA always adds itself and other CA's are added manually
################################################################################
class team_linux::profile::openldapconf {

  $mgldapcf = lookup({ name => 'team_linux::mgldapcf', merge => 'first', default_value => false  })
  $rhtlscacert = lookup({ name => 'team_linux::rhtlscacert', merge => 'first', default_value => '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem' })

  if defined('$mgldapcf') {
    file_line { 'manage_ldap.conf':
      ensure  => present,
      line    => "TLS_CACERT ${rhtlscacert}",
      path    => '/etc/openldap/ldap.conf',
      match   => '^TLS_CACERT\ .*',
      replace => true,
      replace_all_matches_not_matching_line => true,
    }
  }

}
