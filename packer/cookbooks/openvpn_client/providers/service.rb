def load_current_resource
  @current_resource = Chef::Resource::OpenvpnClientService.new(new_resource.name)
  @current_resource
end





def openvpn_service
  return @openvpn_service unless @openvpn_service.nil?

  ## install package
  package new_resource.package do
    action :nothing
  end.run_action(:install)

  ## create runit service for this config
  @openvpn_service = runit_service new_resource.name do
    run_template_name new_resource.template_name
    log_template_name new_resource.template_name
    cookbook new_resource.template_cookbook
    options(
      config_path: config_path,
      config_file: config_file,
      openvpn_binary: new_resource.openvpn_binary,
      run_options: new_resource.run_options
    )
    action :nothing
    subscribes :restart, "file[#{crt_file}]", :delayed
    subscribes :restart, "file[#{auth_file}]", :delayed
    subscribes :restart, "file[#{config_file}]", :delayed
    restart_on_update false
  end

  return @openvpn_service
end

##
## create path for config
##

def config_path
  return @config_path unless @config_path.nil?

  ## create cnfig path
  @config_path = new_resource.config_path

  return @config_path
end

##
## write ca file
##

def crt_file
  return @crt_file unless @crt_file.nil?

  ## create cnfig path
  @crt_file = "#{new_resource.name}.crt"

  ## write ca
  file ::File.join(config_path, @crt_file) do
    content new_resource.ca
    sensitive true
    mode '0600'
    action :nothing
    not_if { new_resource.ca.nil? }
  end.run_action(:create)

  return @crt_file
end

##
## write authfile for auth without prompt
##

def auth_file
  return @auth_file unless @auth_file.nil?

  ## create cnfig path
  @auth_file = "#{new_resource.name}-auth.conf"

  ## write auth file
  file ::File.join(config_path, @auth_file) do
    content(<<-EOF
#{new_resource.auth_user}
#{new_resource.auth_pass}
EOF
    )
    sensitive true
    mode '0600'
    action :nothing
    not_if { new_resource.auth_user.nil? or new_resource.auth_pass.nil? }
  end.run_action(:create)

  return @auth_file
end

##
## write main openvpn conf
##

def config_file
  return @config_file unless @config_file.nil?

  @config_file = "#{new_resource.name}.conf"

  config = new_resource.config.merge({
    'client' => nil,
    'auth-user-pass' => auth_file,
    'ca' => crt_file
  })

  ## main config
  file ::File.join(config_path, @config_file) do
    content (config.keys.sort.map { |k|
      if (config[k])
        <<-EOF
#{k} #{config[k]}
EOF
      else
        <<-EOF
#{k}
EOF
      end
    }.join)
    mode '0644'
    action :nothing
    not_if { new_resource.config.empty? }
  end.run_action(:create)

  return @config_file
end




##
## actions
##

def action_create
  converge_by("Installing OpenVPN client #{new_resource.name}") do
    openvpn_service.run_action(:enable)
  end
end

def action_startup
  converge_by("Create OpenVPN configs #{new_resource.name}") do
    config_file
  end
end
