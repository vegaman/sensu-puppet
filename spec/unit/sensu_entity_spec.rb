require 'spec_helper'
require 'puppet/type/sensu_entity'

describe Puppet::Type.type(:sensu_entity) do
  let(:default_config) do
    {
      name: 'test',
      entity_class: 'proxy'
    }
  end
  let(:config) do
    default_config
  end
  let(:entity) do
    described_class.new(config)
  end

  it 'should add to catalog without raising an error' do
    catalog = Puppet::Resource::Catalog.new
    expect {
      catalog.add_resource entity
    }.to_not raise_error
  end

  it 'should require a name' do
    expect {
      described_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  defaults = {
    'namespace': 'default',
    'deregister': :false,
  }

  # read-only properties
  [
    :system,
    :last_seen,
  ].each do |property|
    it "should not accept #{property}" do
      config[property] = 'foo'
      expect { entity }.to raise_error(Puppet::Error)
    end
  end

  # String properties
  [
    :deregistration_handler,
    :namespace,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 'foo'
      expect(entity[property]).to eq('foo')
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(entity[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(entity[property]).to eq(default_config[property])
      end
    end
  end

  # String regex validated properties
  [
    :name,
    :entity_class,
  ].each do |property|
    it "should not accept invalid #{property}" do
      config[property] = 'foo bar'
      expect { entity }.to raise_error(Puppet::Error, /#{property.to_s} invalid/)
    end
  end

  # Array properties
  [
    :subscriptions,
    :redact,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = ['foo', 'bar']
      expect(entity[property]).to eq(['foo', 'bar'])
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(entity[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(entity[property]).to eq(default_config[property])
      end
    end
  end

  # Integer properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 30
      expect(entity[property]).to eq(30)
    end
    it "should accept valid #{property} as string" do
      config[property] = '30'
      expect(entity[property]).to eq(30)
    end
    it "should not accept invalid value for #{property}" do
      config[property] = 'foo'
      expect { entity }.to raise_error(Puppet::Error, /should be an Integer/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(entity[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(entity[property]).to eq(default_config[property])
      end
    end
  end

  # Boolean properties
  [
    :deregister,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = true
      expect(entity[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = false
      expect(entity[property]).to eq(:false)
    end
    it "should accept valid #{property}" do
      config[property] = 'true'
      expect(entity[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = 'false'
      expect(entity[property]).to eq(:false)
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { entity }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are true, false/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(entity[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(entity[property]).to eq(default_config[property])
      end
    end
  end

  # Hash properties
  [
    :labels,
    :annotations,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = { 'foo': 'bar' }
      expect(entity[property]).to eq({'foo': 'bar'})
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { entity }.to raise_error(Puppet::Error, /should be a Hash/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(entity[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(entity[property]).to eq(default_config[property])
      end
    end
  end

  include_examples 'autorequires' do
    let(:res) { entity }
  end

  it 'should autorequire sensu_handler' do
    handler = Puppet::Type.type(:sensu_handler).new(:name => 'test', :type => 'pipe', :command => 'test')
    catalog = Puppet::Resource::Catalog.new
    config[:deregistration_handler] = ['test']
    catalog.add_resource entity
    catalog.add_resource handler
    rel = entity.autorequire[0]
    expect(rel.source.ref).to eq(handler.ref)
    expect(rel.target.ref).to eq(entity.ref)
  end

  [
    :entity_class,
  ].each do |property|
    it "should require property when ensure => present" do
      config.delete(property)
      config[:ensure] = :present
      expect { entity }.to raise_error(Puppet::Error, /You must provide a #{property}/)
    end
  end
end
