require 'spec_helper'

describe Puppet::Type.type(:sensu_role_binding).provider(:sensuctl) do
  before(:each) do
    @provider = described_class
    @type = Puppet::Type.type(:sensu_role_binding)
    @resource = @type.new({
      :name => 'test',
      :role_ref => 'test-role',
      :subjects => [{'type' => 'User', 'name' => 'test-user'}],
    })
  end

  describe 'self.instances' do
    it 'should create instances' do
      allow(@provider).to receive(:sensuctl_list).with('role-binding').and_return(JSON.parse(my_fixture_read('list.json')))
      expect(@provider.instances.length).to eq(1)
    end

    it 'should return the resource for a role_binding' do
      allow(@provider).to receive(:sensuctl_list).with('role-binding').and_return(JSON.parse(my_fixture_read('list.json')))
      property_hash = @provider.instances[0].instance_variable_get("@property_hash")
      expect(property_hash[:name]).to eq('test')
      expect(property_hash[:role_ref]).to eq('test')
    end
  end

  describe 'create' do
    it 'should create a role_binding' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :role_ref => {'type': 'Role', 'name': 'test-role'},
        :subjects => [{'type' => 'User', 'name' => 'test-user'}],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('RoleBinding', expected_metadata, expected_spec)
      @resource.provider.create
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash[:ensure]).to eq(:present)
    end
  end

  describe 'flush' do
    it 'should update a role_binding subjects' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :role_ref => {'type': 'Role', 'name': 'test-role'},
        :subjects => [{'type' => 'User', 'name' => 'test'}],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('RoleBinding', expected_metadata, expected_spec)
      @resource.provider.subjects = [{'type' => 'User', 'name' => 'test'}]
      @resource.provider.flush
    end
  end

  describe 'destroy' do
    it 'should delete a role_binding' do
      expect(@resource.provider).to receive(:sensuctl_delete).with('role-binding', 'test')
      @resource.provider.destroy
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash).to eq({})
    end
  end
end

