include_recipe 'iptables::default'
container_run = ENV['CONTAINER_RUN'].to_i > 0

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
