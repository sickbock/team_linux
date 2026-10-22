Facter.add(:provisioningstate) do
  setcode 'cat /var/lib/provisioning/state'
end
