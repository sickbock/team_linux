Facter.add(:vmwc2t0d0) do
  setcode do
    @vmwc2t0d0 = File.basename(%x{/usr/bin/readlink /dev/disk/by-path/pci-0000:1b:00.0-scsi-0:0:0:0}.strip)
  end
end

