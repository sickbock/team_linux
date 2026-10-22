###############################################################################
#
# Basic Linux server configuration: to be consumed by 
#   - IAAS server role "baseline"
#   - any  other role for a specific server configuration (by any team)
#
################################################################################
class team_linux::meta_profile::baselinelvm {
# no explicit depencency order:
  contain team_linux::meta_profile::baseline_prepare
  contain team_linux::profile::lvmhiera
  contain team_linux::profile::puppetagent

  Class['team_linux::meta_profile::baseline_prepare'] ->
  Class['team_linux::profile::lvmhiera']

}
