Facter.add(:rsyslog_hostcert_exists) do
  setcode do
    File.exists?('/etc/rsyslog.d/host-cert.pem')
  end
end
