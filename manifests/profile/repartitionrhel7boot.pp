################################################################################
# RHEL 7 VRA bootdisk: Enlarge 2nd partition if there is no 3d 
# Use hard coded values for disk- &  partionsize and hope for the best
################################################################################
class team_linux::profile::repartitionrhel7boot inherits team_linux::profile::parameters {
  if ( $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '7' and $installdsa == true ) {
    $repartition = lookup({ name => 'team_linux::repartitionrhel7boot', value_type => Boolean, merge => 'deep', default_value => false })
    $rhel7disk   = lookup({ name => 'team_linux::rhel7disk', value_type => String, merge => 'first', default_value => 'sda' })
    $szdata      = lookup({ name => 'team_linux::szdsagentvar', default_value => 2  })
    if defined('$repartition') and ! $facts['partitions']["/dev/${rhel7disk}3"] { # no third partition should exist
      # We just take the risk since we get no resources, only orders, so, guess 
      # - boot is always partition "2" 
      # - partition 2 is the last partition
      # and hope for the best
      $rhel7part = "${rhel7disk}2"
      $rhel7boot = "/dev/${rhel7part}"
      $bootpsize = 0 + $facts['partitions']["${rhel7boot}"]['size_bytes'] # partition size in bytes according to facts
      # Quotes are hell with execs
      $rhel7awkd  = "/${rhel7part}/ {print \$4}"
      $awksizestr = shellquote($rhel7awkd) # should be something Puppet can hand over to a shell
      $pv7pe       = 0 + $facts['physical_volumes']["${rhel7boot}"]['pe_count'] # PE's in use according to facts
      $pv7allocpe  = 0 + $facts['physical_volumes']["${rhel7boot}"]['pe_alloc_count'] # PE's in use according to facts
      $perequired  = $szdata*1000/4
      $peavailable = $pv7pe - $pv7allocpe
      if $bootpsize < 28000000000 { # default VRA delivered RHEL 7 LVM partition is roughly 26 GB
        notify {"Boot partition is smaller then 28000000000 bytes" : }
          exec { 'resize_rhel7_boot_partition2':
            command  => "echo -e 'd\n2\nn\np\n2\n\n\nt\n2\n8e\nw\n' | fdisk /dev/${rhel7disk} || : ",
            path     => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            onlyif   => "test $(echo -e 'p\nq\n' |fdisk /dev/${rhel7disk} |awk ${awksizestr}) -lt 30000000 ", # only if partition is still ca 26GB
            provider => 'shell',
          } ->
          exec { 'reread_rhel7_boot_disk':
            command      => "echo 1 > /sys/block/${rhel7disk}/device/rescan", # rescan when discrepancy between kernel and label
            path         => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            onlyif   => "test $(fdisk  -s ${rhel7boot}) -lt $(echo -e 'p\nq\n' |fdisk /dev/${rhel7disk} |awk ${awksizestr}) ", # kernel < label
            provider     => 'shell',
          } ->
          exec { 'partprobe_rhel7':
            command      => 'partprobe', # rescan  alone does'nt seem to doe the job, also do a partprobe or hdparm ... 
            path         => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
            onlyif   => "test $(fdisk  -s ${rhel7boot}) -lt $(echo -e 'p\nq\n' |fdisk /dev/${rhel7disk} |awk ${awksizestr}) ", # kernel < label
            provider     => 'shell',
          }
      } elsif $bootpsize > 28000000000 and $pv7pe < 7000 { # disk partition should be enlarged, but the LVM may not know that yet
        # default VRA delivered RHEL 7 LVM partition is increase but PV extends is still below 7000 
        #notify {"Boot partition: ${bootpsize} bytes" : }
        $awkpes      = '/Allocated PE/ {print $3}' # again, reconcile Puppet and the shell
        $awkpestring = shellquote($awkpes) # this should make both happy
        exec { 'pvresize_rhel7':
          command      => "pvresize ${rhel7boot}", # Puppet LVM module does not know this trick
          path         => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
          onlyif   => "test $(pvdisplay ${rhel7boot} |awk ${awkpestring}) -lt 7000", # only when not yet done
          provider     => 'shell',
        }
      } else {
          if $perequired > $peavailable {
            fail ("Required PE's: ${perequired} is less than available: ${peavailable}"  )
          }
      }
    } elsif $facts['partitions']["/dev/${rhel7disk}3"] {
      if defined('$repartition') {
        fail ( "Partition /dev/${rhel7disk}3 exists, refusing to destroy /dev/${rhel7disk}2" )
      } else {
        notify { "Partition /dev/${rhel7disk}3 exists, cannot claim space to expand /dev/${rhel7disk}2" : }
      }
    }
  }
}
