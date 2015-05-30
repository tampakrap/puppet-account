# == Defined type: account::user
#
# Wrapper around the user resource and various other modules, in order to
# handle a user plus various of his dotfiles. More specifically, it handles:
#  - ~/.ssh/authorized_keys through ssh_authorized_keys resource
#  - ~/.ssh/known_hosts through sshkey resource
#  - ~/.ssh/config through sshuserconfig::remotehost
#  - ~/.git/config through git::config (puppetlabs/git)
#  - ~/.gnupg through through gnupg_key (golja/gnupg)
#  - ~/.forward
#
define account::user (
  $ensure              = 'absent',
  $groups              = [],
  $managehome          = true,
  $purge_ssh_keys      = true,
  $system              = false,
  $shell               = undef,
  $home                = "/home/${name}",
  $uid                 = undef,
  $gid                 = undef,
  $password            = undef,
  $ssh_authorized_keys = {},
  $ssh_known_hosts     = {},
  $ssh_config          = {},
  $git_config          = {},
  $gpg_keys            = {},
  $forward             = undef,
) {
  validate_re($ensure, ['present', 'absent'])
  validate_hash($ssh_authorized_keys)
  validate_hash($ssh_known_hosts)
  validate_hash($ssh_config)
  validate_hash($git_config)
  validate_hash($gpg_keys)
  validate_string($forward)

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
    shell          => $shell,
  }

  if $ensure == 'present' {
    file { "${home}/.ssh":
      ensure  => 'directory',
      owner   => $name,
      group   => $gid,
      mode    => '0600',
      require => User[$name],
    }

    if $forward {
      file { "${home}/.forward":
        content => "# managed by puppet\n\n${forward}\n",
        owner   => $name,
        group   => $gid,
        mode    => '0644',
        require => User[$name],
      }
    } else {
      file { "${home}/.forward": ensure => 'absent' }
    }

    if ! empty($ssh_authorized_keys) {
      $ssh_auth_keys_defaults = {
        'user'    => $name,
        'require' => [
          User[$name],
          File["${home}/.ssh"]
        ],
      }
      create_resources(ssh_authorized_key, $ssh_authorized_keys, $ssh_auth_keys_defaults)
    }

    if ! empty($ssh_known_hosts) {
      $ssh_known_hosts_defaults = {
        'target'  => "${home}/.ssh/known_hosts",
        'require' => [
          User[$name],
          File["${home}/.ssh"]
        ],
      }
      create_resources(sshkey, $ssh_known_hosts, $ssh_known_hosts_defaults)
    }

    if ! empty($ssh_config) {
      $ssh_config_defaults = {
        'unix_user'      => $name,
        'ssh_config_dir' => "${home}/.ssh",
        'require'        => [
          User[$name],
          File["${home}/.ssh"]
        ],
      }
      create_resources(sshuserconfig::remotehost, $ssh_config, $ssh_config_defaults)
    } else {
      file { "${home}/.ssh/config": ensure => 'absent' }
    }

    if ! empty($git_config) {
      $git_config_defaults = {
        'user'    => $name,
        'require' => User[$name],
      }
      create_resources(git::config, $git_config, $git_config_defaults)
    } else {
      file { "${home}/.gitconfig": ensure => 'absent' }
    }

    if ! empty($gpg_keys) {
      include gnupg

      $gpg_keys_defaults = {
        'user'       => $name,
        'key_type'   => 'public',
        'require'    => User[$name],
      }
      create_resources(gnupg_key, $gpg_keys, $gpg_keys_defaults)
    }
  }
}
