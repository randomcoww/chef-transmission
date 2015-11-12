##
## force users to come up with specific gid/uid
##

group node['transmission']['group'] do
  gid node['transmission_wrapper']['gid']
end

user node['transmission']['user'] do
  uid node['transmission_wrapper']['uid']
  gid node['transmission']['group']
  home node['transmission']['home']
end

directory node['transmission']['home'] do
  owner node['transmission']['user']
  group node['transmission']['group']
  recursive true
end

package node['transmission_wrapper']['package'] do
  action :install
end

runit_service 'transmission-daemon' do
  options(
    user: node['transmission']['user'],
    service_binary: node['transmission_wrapper']['service_binary'],
    config_path: node['transmission']['config_dir'],
  )
  restart_on_update false
  action :enable
end

## install openvpn - config should be passed into container at runtime

include_recipe 'openvpn::install'

runit_service 'transmission-openvpn' do
  options(
    config_path: ::File.join(node['transmission']['home'], node['openvpn_client']['config_path']),
    config_file: node['openvpn_client']['config_file'],
    binary: node['openvpn_client']['binary'],
    run_options: node['openvpn_client']['run_options']
  )
  restart_on_update false
  action :enable
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
