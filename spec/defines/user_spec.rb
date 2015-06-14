require 'spec_helper'

describe 'account::user' do
  let(:title) { 'myuser' }
  it { should compile.with_all_deps }
  let(:facts) do
    {
      :osfamily => 'SUSE',
      :operatingsystem => 'openSUSE',
    }
  end

  context 'when using defaults' do
    it { should contain_user(title).with_ensure('absent') }
    it { should_not contain_file("/home/#{title}") }
    it { should_not contain_file("/home/#{title}/.ssh") }
    it { should_not contain_file("/home/#{title}/.ssh/config") }
    it { should_not contain_file("/home/#{title}/.forward") }
    it { should_not contain_file("/home/#{title}/.gitconfig") }
  end

  describe 'when specifying ensure present' do
    context 'when managehome => false' do
      let(:params) do
        {
          :ensure     => 'present',
          :managehome => 'false',
        }
      end

      it { should contain_user(title).with_ensure('present') }
      it { should_not contain_file("/home/#{title}") }
      it { should_not contain_file("/home/#{title}/.ssh") }
      it { should_not contain_file("/home/#{title}/.ssh/config") }
      it { should_not contain_file("/home/#{title}/.forward") }
      it { should_not contain_file("/home/#{title}/.gitconfig") }
    end

    context 'when managehome => true' do
      let(:params) do
        {
          :ensure   => 'present',
          :groups   => ['group1', 'group2'],
          :uid      => '1000',
          :gid      => '100',
          :password => 'p4ssw0rd',
          :shell    => '/bin/bash',
        }
      end

      it do should contain_user(title).with(
        :ensure         => 'present',
        :groups         => ['group1', 'group2'],
        :uid            => '1000',
        :gid            => '100',
        :password       => 'p4ssw0rd',
        :managehome     => true,
        :purge_ssh_keys => true,
        :system         => false,
        :home           => "/home/#{title}",
        :shell          => '/bin/bash',
      ) end

      it do should contain_file("/home/#{title}").with(
        :ensure => 'directory',
        :owner  => title,
        :group  => '100',
        :mode   => '0755',
      ).that_requires("User[#{title}]") end

      it do should contain_file("/home/#{title}/.ssh").with(
        :ensure => 'directory',
        :owner  => title,
        :group  => '100',
        :mode   => '0600',
      ).that_requires("File[/home/#{title}]") end
      it { should contain_file("/home/#{title}/.ssh/config").with_ensure('absent') }
      it { should contain_file("/home/#{title}/.forward").with_ensure('absent') }
      it { should contain_file("/home/#{title}/.gitconfig").with_ensure('absent') }

      context 'when specifying forward' do
        let(:params) do
          {
            :ensure  => 'present',
            :forward => 'myuser@example.com',
          }
        end

        it do should contain_file("/home/#{title}/.forward").with(
          :owner   => title,
          :mode    => '0644',
          :content => "# managed by puppet\n\nmyuser@example.com\n",
        ).that_requires("File[/home/#{title}]") end
      end

      context 'when specifying ssh_authorized_keys' do
        let(:params) do
          {
            :ensure              => 'present',
            :ssh_authorized_keys => {
              'key1' => {
                'type' => 'ssh-rsa'
              },
              'key2' => {
                'key' => 'long_string',
              },
            }
          }
        end

        it do should contain_ssh_authorized_key('key1').with(
          :type => 'ssh-rsa',
          :user => title,
        ).that_requires("File[/home/#{title}]") end
        it { should contain_ssh_authorized_key('key2').with_key('long_string') }
      end

      context 'when specifying ssh_known_hosts' do
        let(:params) do
          {
            :ensure          => 'present',
            :ssh_known_hosts => {
              'host1' => {
                'key' => 'long_string'
              }
            }
          }
        end

        it do should contain_sshkey('host1').with(
          :key    => 'long_string',
          :target => "/home/#{title}/.ssh/known_hosts",
        ).that_requires("File[/home/#{title}]") end
      end

      context 'when specifying ssh_config' do
        let(:params) do
          {
            :ensure     => 'present',
            :ssh_config => {
              'random_github_prj' => {
                'remote_hostname'     => 'github.com',
                'remote_username'     => 'git',
                'private_key_content' => 'long_prv_string',
                'public_key_content'  => 'long_pub_string',
              }
            }
          }
        end

        it do should contain_sshuserconfig__remotehost('random_github_prj').with(
          :remote_hostname => 'github.com',
          :remote_username => 'git',
          :unix_user       => title,
          :ssh_config_dir  => "/home/#{title}/.ssh",
        ).that_requires("File[/home/#{title}]") end
      end

      context 'when specifying git_config' do
        let(:params) do
          {
            :ensure       => 'present',
            :git_config   => {
              'user.name' => {
                'value' => 'My User',
              }
            }
          }
        end

        it do should contain_git__config('user.name').with(
          :value => 'My User',
          :user  => title,
        ).that_requires("File[/home/#{title}]") end
      end

      context 'when specifying gpg_keys' do
        let(:params) do
          {
            :ensure   => 'present',
            :gpg_keys => {
              'myuser_pubkey' => {
                'key_id' => 'AAAAAAAA',
              }
            }
          }
        end

        it { should contain_class('gnupg') }
        it do should contain_gnupg_key('myuser_pubkey').with(
          :key_id     => 'AAAAAAAA',
          :user       => title,
          :key_type   => 'public',
        ).that_requires("File[/home/#{title}]") end
      end

      context 'when specifying home directory' do
        let(:params) do
          {
            :ensure          => 'present',
            :home            => "/var/lib/#{title}",
            :forward         => 'user@example.com',
            :home_mode       => '0750',
            :ssh_known_hosts => {
              'host1' => {
                'key' => 'long_string'
              }
            },
            :ssh_config      => {
              'random_github_prj' => {
                'remote_hostname'     => 'github.com',
                'remote_username'     => 'git',
                'private_key_content' => 'long_prv_string',
                'public_key_content'  => 'long_pub_string',
              }
            }
          }
        end

        it { should contain_user(title).with_home("/var/lib/#{title}") }
        it { should contain_file("/var/lib/#{title}").with_home_mode('0750') }
        it { should contain_file("/var/lib/#{title}/.ssh") }
        it { should contain_file("/var/lib/#{title}/.forward") }
        it { should contain_sshkey('host1').with_target("/var/lib/#{title}/.ssh/known_hosts") }
        it { should contain_sshuserconfig__remotehost('key1').with_ssh_config_dir("/var/lib/#{title}/.ssh") }
      end
    end
  end
end
