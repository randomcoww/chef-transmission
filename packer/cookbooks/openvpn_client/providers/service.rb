def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::OpenvpnClientService.new(new_resource.name)
  @current_resource
end

action :create do

  config_file = "#{new_resource.name}.conf"
  crt_file = "#{new_resource.name}.crt"
  auth_file = "#{new_resource.name}-auth.conf"
  config = new_resource.config.merge({
    'client' => nil,
    'auth-user-pass' => auth_file,
    'ca' => crt_file
  })

  converge_by("Installing OpenVPN Client #{new_resource.name}") do

    ## create cnfig path
    directory new_resource.config_path do
      action :create
    end

    ## install package
    new_resource.packages.each_pair do |pkg, ver|
      package pkg do
        version ver if ver
        action :install
      end
    end

    ## write auth file
    file ::File.join(new_resource.config_path, auth_file) do
      content(<<-EOF
#{new_resource.auth_user}
#{new_resource.auth_pass}
EOF
      )
      sensitive true
      mode '0600'
      action :create
      notifies :restart, "runit_service[#{new_resource.name}]", :delayed
    end

    ## write ca
    file ::File.join(new_resource.config_path, crt_file) do
      content new_resource.ca
      sensitive true
      mode '0600'
      action :create
      notifies :restart, "runit_service[#{new_resource.name}]", :delayed
    end

    ## main config
    file ::File.join(new_resource.config_path, config_file) do
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
      action :create
      notifies :restart, "runit_service[#{new_resource.name}]", :delayed
    end

    ## create runit service for this config
    runit_service new_resource.name do
      run_template_name new_resource.template_name
      log_template_name new_resource.template_name
      cookbook new_resource.template_cookbook
      options(
        config_path: new_resource.config_path,
        config_file: config_file,
        openvpn_binary: new_resource.openvpn_binary,
        run_options: new_resource.run_options
      )
      action :enable
    end
  end
end
