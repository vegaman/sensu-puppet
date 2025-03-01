require 'spec_helper_acceptance'

describe 'sensu::backend class', unless: RSpec.configuration.sensu_cluster do
  node = hosts_as('sensu_backend')[0]
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu': }
      class { '::sensu::backend':
        password     => 'supersecret',
        old_password => 'P@ssw0rd!',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
    describe package('sensu-go-agent'), :node => node do
      it { should_not be_installed }
    end
  end

  context 'backend and agent' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu': }
      class { '::sensu::backend':
        password     => 'supersecret',
        old_password => 'P@ssw0rd!',
      }
      class { '::sensu::agent':
        backends => ['sensu_backend:8081'],
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
    describe service('sensu-agent'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context 'reset admin password and opt-out tessen' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu::backend':
        password      => 'P@ssw0rd!',
        old_password  => 'supersecret',
        tessen_ensure => 'absent',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end

    it 'should opt-out of tessen' do
      on node, 'sensuctl tessen info --format json' do
        data = JSON.parse(stdout)
        expect(data['opt_out']).to eq(true)
      end
    end
  end
end
