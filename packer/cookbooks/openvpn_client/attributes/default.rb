node.default['openvpn_client']['openvpn_binary'] = '/usr/sbin/openvpn'
node.default['openvpn_client']['packages'] = {
  'openvpn' => nil
}
node.default['openvpn_client']['service_name'] = 'openvpn'

node.default['openvpn_client']['config_path'] = '/etc/openvpn'
