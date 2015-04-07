## do all networking stuff at startup. some require privileged mode

## add static routes

route node['route']['network'] do
  gateway node['route']['gateway']
end

## add iptables riles

#include_recipe 'iptables::default'

iptables_rule "transmission-route" do
  variables({
    :user => node['transmission']['user'],
    :dev => node['openvpn_client']['dev']
  })
end

#execute 'load_iptables' do
#  command '/sbin/iptables-restore < /etc/iptables/general'
#end

## write openvpn configs. data bag should be available during startup

bag = Chef::EncryptedDataBagItem.load(ENV['DATA_BAG'], ENV['BAG_NAME']).to_hash

config = bag['config'] || {}
config.merge!( { "dev" => node['openvpn_client']['dev'] } )

openvpn_client_service 'openvpn' do
  config config
  auth_user bag['user']
  auth_pass bag['pass']
  ca bag['ca']

  action :startup
end
