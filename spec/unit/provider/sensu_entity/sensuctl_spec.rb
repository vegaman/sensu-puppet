require 'spec_helper'

describe Puppet::Type.type(:sensu_entity).provider(:sensuctl) do
  before(:each) do
    @provider = described_class
    @resource = Puppet::Type.type(:sensu_entity).new({name: 'test'})
  end

  describe 'self.instances' do
    it 'should create instances' do
      allow(@provider).to receive(:sensuctl_list).with('entity').and_return(JSON.parse(my_fixture_read('entity_list.json')))
      expect(@provider.instances.length).to eq(1)
    end

    it 'should return the @resource for a entity' do
      allow(@provider).to receive(:sensuctl_list).with('entity').and_return(JSON.parse(my_fixture_read('entity_list.json')))
      property_hash = @provider.instances[0].instance_variable_get("@property_hash")
      expect(property_hash[:name]).to eq('sensu-backend.example.com')
    end
  end

  describe 'create' do
    it 'should create a entity' do
      @resource[:entity_class] = 'proxy'
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :entity_class => 'proxy',
        :deregister => false,
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('Entity', expected_metadata, expected_spec)
      @resource.provider.create
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash[:ensure]).to eq(:present)
    end
  end

  describe 'flush' do
    it 'should update a entity labels' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
        :labels => {'foo' => 'bar'},
      }
      expected_spec = {
        :deregister => false,
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('Entity', expected_metadata, expected_spec)
      @resource.provider.labels = {'foo' => 'bar'}
      @resource.provider.flush
    end
  end

  describe 'destroy' do
    it 'should delete a entity' do
      expect(@resource.provider).to receive(:sensuctl_delete).with('entity', 'test')
      @resource.provider.destroy
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash).to eq({})
    end
  end
end

