Facter.add(:cryptopolicy) do
  setcode do
    Facter::Util::Resolution.exec("update-crypto-policies --show")
  end
end

