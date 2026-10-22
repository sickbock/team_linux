Facter.add(:ds_agentvers) do
  setcode do
    @ds_agentvers = Facter::Core::Execution.exec("rpm --qf '%{version}-%{release}' -q ds_agent").chomp
  end
end
