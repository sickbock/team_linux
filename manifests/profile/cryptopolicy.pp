################################################################################
# Configure crypto policies on RHEL 8 - mainly for proud patrons of the
# cryptographic heritage like CAK, so we can change the setting to LEGACY
# for systems/roles that need to do business with the CAK legacy!
################################################################################
class team_linux::profile::cryptopolicy {
  #notify{"Running rhel8python":}
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] >= '8' ) {
    $policysetting = lookup({ name => 'team_linux::cryptopolicies', value_type => String, merge => 'deep', default_value => 'DEFAULT' })

    if $facts['cryptopolicy'] != "${policysetting}" {
      exec { 'update-crypto-policies':
        command  => "update-crypto-policies --set ${policysetting}",
        path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
        provider => 'shell',
      }
    }

  }
}
