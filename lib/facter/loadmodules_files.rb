Facter.add(:loadmodules_files) do
  setcode do
    Dir.glob('/etc/sysconfig/modules/{*,.*}').empty?
  end
end
