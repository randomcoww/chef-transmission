actions :create
default_action :create

attribute :name, :kind_of => [String], :name_attribute => true
attribute :config_path, :kind_of => [String], :default => node['openvpn_client']['config_path']
attribute :packages, :kind_of => [Hash], :default => node['openvpn_client']['packages']
attribute :openvpn_binary, :kind_of => [String], :default => node['openvpn_client']['openvpn_binary']
attribute :template_name, :kind_of => [String], :default => 'openvpn'
attribute :template_cookbook, :kind_of => [String], :default => 'openvpn_client'
attribute :run_options, :kind_of => [String], :default => ''
attribute :config, :kind_of => [Hash], :default => {}

attribute :auth_user, :kind_of => [String]
attribute :auth_pass, :kind_of => [String]
attribute :ca, :kind_of => [String]
