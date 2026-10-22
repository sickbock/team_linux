Facter.add(:kerberosrealm) do
  setcode 'klist -k 2>/dev/null|cut -d@ -f2 |sort -u|egrep "CAK-BZ.LOCAL|IPAPROD.HETCAK.NL"'
end

