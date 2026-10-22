Facter.add(:vmwc2t0d1) do
  setcode do
    @vmwc2t0d1 = File.basename(%x{/usr/bin/readlink /dev/disk/by-path/pci-0000:1b:00.0-scsi-0:0:1:0}.strip)
  end
end

