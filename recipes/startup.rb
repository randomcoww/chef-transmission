## make transmission user and directories now so uid/gid can be configured at container start

# delete current group and replace with new gid
user node['transmission']['user'] do
  action :remove
end
 
group node['transmission']['group'] do
  action :remove
end

group node['transmission']['group'] do
  gid ENV['TRANSMISSION_GID'] || node['transmission_wrapper']['gid']
  action :create
end

user node['transmission']['user'] do
  uid ENV['TRANSMISSION_UID'] || node['transmission_wrapper']['uid']
  gid node['transmission']['group']
  home node['transmission']['home']
  action :create
end

## do all networking stuff at startup. some require privileged mode
::Chef::Resource.send(:include, TransmissionWrapper::Helper)

## add static routes
node['route']['networks'].each { |n|
  route n do
    gateway default_gateway
  end
}

## add iptables riles

iptables_rule "transmission-route" do
  variables({
    :user => node['transmission']['user'],
    :dev => ENV['OPENVPN_TUN_DEVICE'] || node['openvpn_client']['dev']
  })
end

execute 'load_iptables' do
  command '/sbin/iptables-restore < /etc/iptables/general'
end
