# == Defined type: account::user
#
# Wrapper around the user resource, that also handles:
#  - ~/.ssh/authorized_keys through ssh_authorized_keys resource
#  - ~/.ssh/known_hosts through sshkey resource
#  - ~/.ssh/config through sshuserconfig::remotehost
#  - ~/.git/config through git::config (puppetlabs/git)
#  - ~/.forward
#
define account::user (
  $ensure              = 'absent',
  $groups              = [],
  $managehome          = true,
  $purge_ssh_keys      = true,
  $system              = false,
  $home                = "/home/${name}",
  $uid                 = undef,
  $gid                 = undef,
  $password            = undef,
  $ssh_authorized_keys = {},
  $ssh_known_hosts     = {},
  $ssh_config          = {},
  $git_config          = {},
  $forward             = undef,
) {
  validate_re($ensure, ['present', 'absent'])
  validate_hash($ssh_authorized_keys)
  validate_hash($ssh_known_hosts)
  validate_hash($ssh_config)
  validate_hash($git_config)

  user { $name:
    ensure         => $ensure,
    uid            => $uid,
    gid            => $gid,
    groups         => $groups,
    home           => $home,
    managehome     => $managehome,
    password       => $password,
    purge_ssh_keys => $purge_ssh_keys,
    system         => $system,
  }

  if $ensure == 'present' {
    file { "/home/${name}/.ssh":
      ensure  => 'directory',
      owner   => $name,
      group   => $gid,
      mode    => '0600',
      require => User[$name],
    }

    if $forward {
      file { "/home/${name}/.forward":
        content => "# managed by puppet\n\n${forward}\n",
        owner   => $name,
        group   => $gid,
        mode    => '0644',
        require => User[$name],
      }
    } else {
      file { "/home/${name}/.forward": ensure => 'absent' }
    }

    if $ssh_authorized_keys {
      $defaults = {
        'user'    => $name,
        'require' => [
          User[$name],
          File["${name}/.ssh"]
        ],
      }
      create_resources(ssh_authorized_key, $ssh_authorized_keys, $defaults)
    }

    if $ssh_known_hosts {
      $defaults = {
        'target'  => "/home/${name}/.ssh/known_hosts",
        'require' => [
          User[$name],
          File["${name}/.ssh"]
        ],
      }
      create_resources(sshkey, $ssh_known_hosts, $defaults)
    }

    if $ssh_config {
      $defaults = {
        'unix_user' => $name,
        'require'   => [
          User[$name],
          File["${name}/.ssh"]
        ],
      }
      create_resources(sshuserconfig::remotehost, $ssh_config, $defaults)
    } else {
      file { "/home/${name}/.ssh/config": ensure => 'absent' }
    }

    if $git_config {
      $defaults = {
        'user'    => $name,
        'require' => User[$name],
      }
      create_resources(git::config, $git_config, $defaults)
    } else {
      file { "/home/${name}/.gitconfig": ensure => 'absent' }
    }
  }
}
