include_recipe 'iptables::default'
container_run = node['transmission_wrapper']['env']['container_run']

iptables_rule "transmission-route" do
  variables({
    :user => node['transmission']['user'],
    :dev => node['openvpn_client']['dev']
  })
end

execute 'load_iptables' do
  command '/sbin/iptables-restore < /etc/iptables/general'
  only_if { container_run }
end
