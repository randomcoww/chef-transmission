#
# Cookbook Name:: transmission_wrapper
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

node['transmission_wrapper']['packages'].each_pair do |pkg, ver|
  package pkg do
    action :install
    version ver if ver
  end
end

directory node['transmission']['home'] do
  owner node['transmission']['user']
  group node['transmission']['group']
end

file ::File.join(node['transmission']['config_dir'], 'settings.json') do
  content node['transmission']['settings'].to_json
  owner node['transmission']['user']
  group node['transmission']['group']
  mode "0644"
  #notifies :restart, "service[transmission-daemon]", :delayed
end

runit_service 'transmission-daemon' do
  options(
    user: node['transmission']['user'],
    service_binary: node['transmission_wrapper']['service_binary'],
    config_path: node['transmission']['config_dir'],
  )
  action :enable
end
