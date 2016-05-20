# == Class: account
#
# Sets up regular and system users and groups
#
# == Parameters
#
# [*groups*]
# A hash with groups, where the value is a hash with the attributes
#
# [*groups_defaults*]
# A hash with the default attributes of the groups
#
# [*users*]
# A hash with the users, where the value is a hash with the attributes
#
# [*users_defaults*]
# A hash with the default attributes of the users
#
class account (
  $groups          = {},
  $groups_defaults = {},
  $users           = {},
  $users_defaults  = {},
) {
  validate_hash($groups)
  validate_hash($groups_defaults)
  validate_hash($users)
  validate_hash($users_defaults)

  if ! empty($groups) {
    $_groups = hiera_hash('account::groups',$groups)
    create_resources(group, $_groups, $groups_defaults)
  }

  if ! empty($users) {
    $_users = hiera_hash('account::users',$users)
    create_resources(account::user, $_users, $users_defaults)
  }
}
