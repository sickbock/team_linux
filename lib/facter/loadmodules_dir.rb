Facter.add(:loadmodules_dir) do
  setcode do
    File.directory?('/etc/rc.modules')
  end
end
