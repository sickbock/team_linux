Facter.add(:zabbix_exists) do
  setcode do
    !Dir.glob('/usr/sbin/zabbix_agent*').empty?
  end
end
