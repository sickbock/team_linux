Facter.add(:postgresmodule) do
  setcode do
    `dnf module list --enabled postgresql 2>/dev/null | awk '/postgresql/ {ORS=""; print $2}'`
  end
end
