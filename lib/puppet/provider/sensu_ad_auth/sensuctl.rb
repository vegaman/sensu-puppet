require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sensuctl'))

Puppet::Type.type(:sensu_ad_auth).provide(:sensuctl, :parent => Puppet::Provider::Sensuctl) do
  desc "Provider sensu_ad_auth using sensuctl"

  mk_resource_methods

  def self.instances
    auths = []

    data = sensuctl_list('auth', false)

    auth_types = sensuctl_auth_types()
    data.each do |d|
      auth = {}
      auth[:ensure] = :present
      auth[:name] = d['metadata']['name']
      if auth_types[auth[:name]] != 'AD'
        next
      end
      auth[:groups_prefix] = d['groups_prefix']
      auth[:username_prefix] = d['username_prefix']
      binding = {}
      group_search = {}
      user_search = {}
      servers = []
      d['servers'].each do |server|
        s = {}
        s['host'] = server['host']
        s['port'] = server['port']
        s['insecure'] = server['insecure']
        s['security'] = server['security']
        s['trusted_ca_file'] = server['trusted_ca_file']
        s['client_cert_file'] = server['client_cert_file']
        s['client_key_file'] = server['client_key_file']
        binding[s['host']] = server['binding']
        group_search[s['host']] = server['group_search']
        user_search[s['host']] = server['user_search']
        servers << s
      end
      auth[:servers] = servers
      auth[:server_binding] = binding
      auth[:server_group_search] = group_search
      auth[:server_user_search] = user_search
      auths << new(auth)
    end
    auths
  end

  def self.prefetch(resources)
    auths = instances
    resources.keys.each do |name|
      if provider = auths.find { |c| c.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  type_properties.each do |prop|
    define_method "#{prop}=".to_sym do |value|
      @property_flush[prop] = value
    end
  end

  def create
    spec = {}
    metadata = {}
    metadata[:name] = resource[:name]
    spec[:servers] = []
    resource[:servers].each do |server|
      host = server['host']
      server['binding'] = resource[:server_binding][host] if resource[:server_binding]
      server['group_search'] = resource[:server_group_search][host]
      server['user_search'] = resource[:server_user_search][host]
      spec[:servers] << server
    end
    spec[:groups_prefix] = resource[:groups_prefix] if resource[:groups_prefix]
    spec[:username_prefix] = resource[:username_prefix] if resource[:username_prefix]
    begin
      sensuctl_create('ad', metadata, spec, 'authentication/v2')
    rescue Exception => e
      raise Puppet::Error, "sensuctl create #{resource[:name]} failed\nError message: #{e.message}"
    end
    @property_hash[:ensure] = :present
  end

  def flush
    if !@property_flush.empty?
      spec = {}
      metadata = {}
      metadata[:name] = resource[:name]
      spec[:servers] = []
      (@property_flush[:servers] || resource[:servers]).each do |server|
        host = server['host']
        if @property_flush[:server_binding]
          server['binding'] = @property_flush[:server_binding][host]
        else
          server['binding'] = resource[:server_binding][host] if resource[:server_binding]
        end
        if @property_flush[:server_group_search]
          server['group_search'] = @property_flush[:server_group_search][host]
        else
          server['group_search'] = resource[:server_group_search][host]
        end
        if @property_flush[:server_user_search]
          server['user_search'] = @property_flush[:server_user_search][host]
        else
          server['user_search'] = resource[:server_user_search][host]
        end
        spec[:servers] << server
      end
      if @property_flush[:groups_prefix]
        spec[:groups_prefix] = @property_flush[:groups_prefix]
      else
        spec[:groups_prefix] = resource[:groups_prefix]
      end
      if @property_flush[:username_prefix]
        spec[:username_prefix] = @property_flush[:username_prefix]
      else
        spec[:username_prefix] = resource[:username_prefix]
      end
      begin
        sensuctl_create('ad', metadata, spec, 'authentication/v2')
      rescue Exception => e
        raise Puppet::Error, "sensuctl create #{resource[:name]} failed\nError message: #{e.message}"
      end
    end
    @property_hash = resource.to_hash
  end

  def destroy
    begin
      sensuctl_delete('auth', resource[:name])
    rescue Exception => e
      raise Puppet::Error, "sensuctl delete auth #{resource[:name]} failed\nError message: #{e.message}"
    end
    @property_hash.clear
  end
end

