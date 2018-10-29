require 'spec_helper_acceptance'

describe 'sensu_mutator', if: RSpec.configuration.sensu_full do
  node = only_host_with_role(hosts, 'sensu_backend')
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_mutator { 'test':
        command        => 'test',
        runtime_assets => ['test'],
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid mutator' do
      on node, 'sensuctl mutator info test --format json' do
        data = JSON.parse(stdout)
        expect(data['command']).to eq('test')
        expect(data['runtime_assets']).to eq(['test'])
      end
    end
  end

  context 'update mutator' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_mutator { 'test':
        command        => 'test',
        timeout        => 60,
        runtime_assets => ['test2'],
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid mutator with updated propery' do
      on node, 'sensuctl mutator info test --format json' do
        data = JSON.parse(stdout)
        expect(data['timeout']).to eq(60)
        expect(data['runtime_assets']).to eq(['test2'])
      end
    end
  end

  context 'ensure => absent' do
    it 'should remove without errors' do
      pp = <<-EOS
      include ::sensu::backend
      sensu_mutator { 'test': ensure => 'absent' }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe command('sensuctl mutator info test'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end

