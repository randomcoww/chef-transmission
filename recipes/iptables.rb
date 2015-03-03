include_recipe 'iptables::default'

iptables_rule "transmission-route" do
  variables({
    :user => node['transmission']['user'],
    :dev => node['openvpn_client']['dev']
  })
end
