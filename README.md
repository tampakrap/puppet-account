puppet-account
=============

[![Build Status](https://travis-ci.org/tampakrap/puppet-account.png?branch=master)](https://travis-ci.org/tampakrap/puppet-account)
[![Puppet Forge](http://img.shields.io/puppetforge/v/tampakrap/account.svg)](https://forge.puppetlabs.com/tampakrap/account)

Wrapper around the user resource and various other modules, in order to handle
a user plus various of his dotfiles. More specifically, it handles:
  - `~/.ssh/authorized_keys` through [ssh_authorized_key](https://docs.puppetlabs.com/references/latest/type.html#sshauthorizedkey)
  resource
  - `~/.ssh/known_hosts` through [sshkey](https://docs.puppetlabs.com/references/latest/type.html#sshkey)
  resource
  - `~/.ssh/config` through `ssh::client::config::user` ([saz/ssh](https://forge.puppetlabs.com/saz/ssh))
  - private and public ssh key pair through `ssh_keygen` ([maestrodev/ssh_keygen](https://forge.puppetlabs.com/maestrodev/ssh_keygen))
  - `~/.git/config` through `git::config` ([puppetlabs/git](https://forge.puppetlabs.com/puppetlabs/git))
  - `~/.gnupg` through through `gnupg_key` ([golja/gnupg](https://forge.puppetlabs.com/golja/gnupg))

## Usage

Below is an example using hiera:

```yaml
account::groups:
  ssh:
    ensure: 'present'
account::users:
  realperson:
    ensure: 'present'
    groups:
      - 'ssh'
      - 'wheel'
    ssh_authorized_keys:
      realperson@home:
        type: 'ssh-rsa'
        key: 'key_contents_here'
    uid: '2001'
  git:
    ensure: 'present'
    gid: 'git'
    groups:
      - 'ssh'
    purge_ssh_keys: false
    system: true
  root:
    ensure: 'present'
    gid: '0'
    groups:
      - 'root'
    home: '/root'
    home_mode: '0750'
    password: '!'
    system: true
    uid: '0'
account::users_defaults:
  gid: '100'
```
