Facter.add(:tainted) do
  setcode do
    @tainted = Facter::Core::Execution.exec("echo -ne $(cat /proc/sys/kernel/tainted)").chomp
  end
end
