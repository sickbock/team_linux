class team_linux::profile::manage_ca_trust {

# Remove bundle containing pre-2021 Internal Issuing CA after 2025-02-05
# and blacklist the certificate in data/params.eyaml
#  file { '/etc/pki/ca-trust/source/anchors/katello-server-ca.pem':
#    ensure => absent,
#  }

  # allow overwriting the whole whitelist  via node yaml using merge type first 
  $anchors   = lookup({ name => "team_linux::ca_trust_anchors",  merge => 'first', default_value => undef })
  $blacklist = lookup({ name => "team_linux::ca_trust_blacklist",  merge => 'deep', default_value => undef  })
  #notify {"Anchors: ${anchors}":}
  #notify {"Blacklist: ${blacklist}":}

  if ! defined(Package[p11-kit-trust]) {
    package{ 'p11-kit-trust':
      ensure => present,
    }
  }
  if ! defined(Package[ca-certificates]) {
    package{ 'ca-certificates':
      ensure => present,
    }
  }

  if defined('$anchors') {
    keys($anchors).each | $anchor | {
      $anchorcert = $anchors["${anchor}"]
      $pkcs11id   = $anchorcert['pkcs11id']
      $pem        = $anchorcert['pem']
  
      # print values
      #notify{"Anchor name: ${anchor}":} # key name
      #notify{"Anchor ID: ${pkcs11id}":} # anchor URI
      #notify{"Anchor PEM: ${pem}":}     # certificate
  
      # Removing the file does not remove the certificate from the bundle
      # so, removing the file here is for testing purposes only, mov the 
      # certificate to the blacklist instead if that is what you want
      if $pem == "remove" {
        file { "/etc/pki/ca-trust/source/anchors/${anchor}.pem":
          ensure => absent,
        }
      } else {
        file { "/etc/pki/ca-trust/source/anchors/${anchor}.pem":
          ensure => file,
          content => inline_epp($pem),
        } ~>
        exec{"update_anchor_${anchor}":
          command     => 'update-ca-trust',
          timeout     => 0,
          #unless      => "trust list --filter=ca-anchors | grep ${pkcs11id}",
          path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
          refreshonly => true,
        } 
      }
    }
  }
  if $blacklist != undef {
    keys($blacklist).each | $black | {
      $blackcert       = $blacklist["${black}"]
      $blackpkcs11id   = $blackcert['pkcs11id']
      $blackpem        = $blackcert['pem']

      $anchornames = $anchors.keys()
      #notify {"Is ${black} in anchornames ? => $anchornames " : }
      if ! ( $black in $anchornames ) {
        #notify {"Start processing $black" :}
        file { "/etc/pki/ca-trust/source/anchors/${black}.pem":
          ensure => absent,
        } ~> # "remove" only for testing purposes or mistakes
        if $blackpem == "remove" {
          file { "/etc/pki/ca-trust/source/blacklist/${black}.pem":
            ensure => absent,
          } 
        } else {
          file { "/etc/pki/ca-trust/source/blacklist/${black}.pem":
            ensure => file,
            content => inline_epp($blackpem),
          } ~>
          exec{"update_anchor_${anchor}":
            command     => 'update-ca-trust',
            timeout     => 0,
            #unless      => "trust list --filter=blacklist | grep ${pkcs11id}",
            path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            refreshonly => true,
          } 
        }
      } else {
         fail ( "Key ${black} is also in the whitelist (anchors)" )
      }
    }
  }

}
