#
# Cookbook Name:: transmission_wrapper
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

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
