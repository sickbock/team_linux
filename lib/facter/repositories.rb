Facter.add(:repositories) do
  setcode do
    cmd_listrepos = %q{/etc/facter/facts.d/repolist.sh}
    by_repo = Facter::Core::Execution.execute( cmd_listrepos ).each_line
    repo_hash = {}
    by_repo.each do | repo |
      arr = repo.gsub(/\n/,"").split(";")
      if arr[1] == "1"
        repo_hash[arr[0]] = 'enabled'
      else
        repo_hash[arr[0]] = 'disabled'
      end
    end
    repo_hash
  end
end
