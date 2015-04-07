actions :create, :startup
default_action :create

attribute :name, :kind_of => [String], :name_attribute => true

attribute :bind_package, :kind_of => [String], :default => 'bind9'
attribute :service_name, :kind_of => [String], :default => 'bind9'

attribute :user, :kind_of => [String], :default => 'bind'
attribute :group, :kind_of => [String], :default => 'bind'

attribute :conf_path, :kind_of => [String], :default => '/etc/bind'
attribute :zone_path, :kind_of => [String], :default => '/var/cache/bind'

attribute :named_conf_template, :kind_of => [String], :default => 'named.conf.erb'
attribute :named_conf_cookbook, :kind_of => [String], :default => 'bind_git'
attribute :named_conf_variables, :kind_of => [Hash], :default => {
  'allow_recursion' => [
    '127.0.0.1',
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
  ]
}

attribute :zone_conf_name, :kind_of => [String], :default => 'zone.conf'

attribute :zone_conf_template, :kind_of => [String], :default => 'zone.conf.erb'
attribute :zone_conf_cookbook, :kind_of => [String], :default => 'bind_git'
attribute :zone_conf_variables, :kind_of => [Hash], :default => {}

attribute :git_repo, :kind_of => [String]
attribute :git_branch, :kind_of => [String]
attribute :git_key, :kind_of => [String]
