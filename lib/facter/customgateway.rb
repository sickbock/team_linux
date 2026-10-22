Facter.add(:customgateway) do
  setcode do
    @customgateway = Facter::Core::Execution.exec("test $(ls -l /sys/class/net/e*|wc -l) -eq 1 && awk -F= '/^GATEWAY=/ {print $2}' /etc/sysconfig/network-scripts/ifcfg-$(basename /sys/class/net/e*)").chomp
  end
end
