Facter.add(:vmwc0t0d2) do
  setcode do
    @vmwc0t0d2 = File.basename(%x{/usr/bin/readlink /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:2:0}.strip)
  end
end

