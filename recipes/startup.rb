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
    :dev => node['openvpn_client']['dev']
  })
end

execute 'load_iptables' do
  command '/sbin/iptables-restore < /etc/iptables/general'
end
