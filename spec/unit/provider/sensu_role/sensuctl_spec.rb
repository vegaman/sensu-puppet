require 'spec_helper'

describe Puppet::Type.type(:sensu_role).provider(:sensuctl) do
  before(:each) do
    @provider = described_class
    @type = Puppet::Type.type(:sensu_role)
    @resource = @type.new({
      :name => 'test',
      :rules => [{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ['']}]
    })
  end

  describe 'self.instances' do
    it 'should create instances' do
      allow(@provider).to receive(:sensuctl_list).with('role').and_return(JSON.parse(my_fixture_read('role_list.json')))
      expect(@provider.instances.length).to eq(1)
    end

    it 'should return the resource for a role' do
      allow(@provider).to receive(:sensuctl_list).with('role').and_return(JSON.parse(my_fixture_read('role_list.json')))
      property_hash = @provider.instances[0].instance_variable_get("@property_hash")
      expect(property_hash[:name]).to eq('prod-admin')
      expect(property_hash[:rules]).to include({'verbs' => ['get','list','create','update','delete'], 'resources' => ['*'], 'resource_names' => []})
    end
  end

  describe 'create' do
    it 'should create a role' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :rules => [{'verbs' => ['get','list'], 'resources' => ['checks'], 'resource_names' => ['']}],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('Role', expected_metadata, expected_spec)
      @resource.provider.create
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash[:ensure]).to eq(:present)
    end
  end

  describe 'flush' do
    it 'should update a role rule' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :rules => [{'verbs' => ['get','list'], 'resources' => ['*'], 'resource_names' => ['']}],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('Role', expected_metadata, expected_spec)
      @resource.provider.rules = [{'verbs' => ['get','list'], 'resources' => ['*'], 'resource_names' => ['']}]
      @resource.provider.flush
    end
  end

  describe 'destroy' do
    it 'should delete a role' do
      expect(@resource.provider).to receive(:sensuctl_delete).with('role', 'test')
      @resource.provider.destroy
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash).to eq({})
    end
  end
end

