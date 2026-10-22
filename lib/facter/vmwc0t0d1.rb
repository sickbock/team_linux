Facter.add(:vmwc0t0d1) do
  setcode do
    @vmwc0t0d1 = File.basename(%x{/usr/bin/readlink /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:1:0}.strip)
  end
end

