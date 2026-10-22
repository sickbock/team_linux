Facter.add(:etc_facter_facts_dir) do
  setcode do
    File.directory?('/etc/facter/facts.d')
  end
end
