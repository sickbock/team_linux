################################################################################
# PostgreSQL Puppetmodule lacks Hiera support, work around the issue like
# https://ask.puppet.com/question/32413/how-to-create-multiple-postgresql-databases-via-hiera/
#   
################################################################################
class team_linux::profile::postgreshiera inherits team_linux::profile::parameters {
  class {'postgresql::server':}  

  # Create a hash from Hiera Data with the Databases
  #Hiera 3: # $myPostgresDb = hiera('postgresql::server::db', {})
  $myPostgresDb = lookup({name => 'postgresql::server::db', value_type => Hash, merge => 'deep', default_value => undef }) 

  # With Create Resource Converts Databases hash into a set of resources
  create_resources('postgresql::server::db', $myPostgresDb)

  # Create a hash from Hiera Data with the access rules
  #Hiera 3: #$myPg_hba_rule = hiera('postgresql::server::pg_hba_rule', {})
  $myPg_hba_rule = lookup({name => 'postgresql::server::pg_hba_rule', value_type => Hash, merge => 'deep', default_value => undef }) 

  # With Create Resource Converts pg_hba_rule hash into a set of resources
  create_resources('postgresql::server::pg_hba_rule', $myPg_hba_rule)

   # Don't implement the following, unless you want to manage database role settings per datbase role individually all the time!
#  # Create a hash from Hiera Data with the role parameters
#  $myPg_role = lookup({name => 'postgresql::server::role', value_type => Hash, merge => 'deep', default_value => undef })
#  # With Create Resource Converts postgresql::server::role hash into a set of resources
#  create_resources('postgresql::server::role', $myPg_role)

  # repeat
  #$mydb_grant = lookup({name => 'postgresql::server::database_grant', value_type => Hash, merge => 'deep', default_value => undef }) 
  #create_resources('postgresql::server::database_grant', $mydb_grant)

}
