require 'spec_helper'

describe 'account' do
  it { should contain_class('account') }
  it { should compile.with_all_deps }

  context 'when adding group' do
    context 'without defaults' do
      it do should contain_group('mygrp').with(
        'gid'    => '50',
        'system' => true,
      ) end
      it do should contain_group('myothergrp').with(
        'gid'    => '200',
        'system' => false,
      ) end
      it { should_not contain_group('mygrp').with_provider('ldap') }
    end

    context 'with defaults' do
      let(:params) { {:groups_defaults => { 'provider' => 'ldap' } } }
      it do should contain_group('mygrp').with(
        'gid'      => '50',
        'provider' => 'ldap',
      ) end
      it do should contain_group('myothergrp').with(
        'system'   => false,
        'provider' => 'ldap',
      ) end
    end
  end

  context 'when adding user' do
    context 'without defaults' do
      it do should contain_user('myuser').with(
        'uid'    => '50',
        'system' => true,
      ) end
      it do should contain_user('myotheruser').with(
        'uid'    => '200',
        'system' => false,
      ) end
      it { should_not contain_group('myuser').with_gid('600') }
    end

    context 'with defaults' do
      let(:params) { {:users_defaults => { 'gid' => '250' } } }
      it do should contain_user('myuser').with(
        'gid'    => '250',
        'system' => true,
      ) end
      it do should contain_user('myotheruser').with(
        'gid'    => '250',
        'system' => false,
      ) end
    end
  end
end
