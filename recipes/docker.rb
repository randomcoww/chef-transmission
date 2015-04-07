##
## force users to come up with specific gid/uid
##

group node['transmission']['group'] do
  gid node['transmission_wrapper']['gid']
  not_if { node['transmission_wrapper']['gid'].nil? and node['transmission_wrapper']['uid'].nil? }
end

user node['transmission']['user'] do
  uid node['transmission_wrapper']['uid']
  gid node['transmission']['group']
  home node['transmission']['home']
  not_if { node['transmission_wrapper']['uid'].nil? }
end

directory node['transmission']['home'] do
  owner node['transmission']['user']
  group node['transmission']['group']
  recursive true
end

package node['transmission_wrapper']['package'] do
  action :install
end

##
## config path
##

file ::File.join(node['transmission']['config_dir'], 'settings.json') do
  content node['transmission_wrapper']['settings'].to_json
  owner node['transmission']['user']
  group node['transmission']['group']
  mode "0644"
  ## don't overwrite existing setting from mount path
  #action :create_if_missing
end

runit_service 'transmission-daemon' do
  options(
    user: node['transmission']['user'],
    service_binary: node['transmission_wrapper']['service_binary'],
    config_path: node['transmission']['config_dir'],
  )
  action :enable
end

## install openvpn - ignore if data bag is not available during build

bag = {}

begin
  bag = Chef::EncryptedDataBagItem.load(ENV['DATA_BAG'], ENV['BAG_NAME']).to_hash
rescue
end

config = bag['config'] || {}
config.merge!( { "dev" => node['openvpn_client']['dev'] } )

openvpn_client_service 'openvpn' do
  config config
  auth_user bag['user']
  auth_pass bag['pass']
  ca bag['ca']
end

## install iptables packages

include_recipe 'iptables::default'

## create internal dns server with just default zones

bind_git_static "internal_ns" do
  service_name "bind"
  user 'bind'
  group 'bind'
  named_conf_variables ({
    'allow_recursion' => [
      '127.0.0.1'
    ]
  })
end

## create startup script for phusion baseimage

file "/etc/my_init.d/95_chef_startup" do
  content(<<-EOF
#!/bin/bash
#{node['chef_client']['bin']} #{node['chef_client']['daemon_options'].join(' ')} -o transmission_wrapper::startup
  EOF
  )
  mode '0755'
end
