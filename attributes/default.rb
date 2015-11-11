node.default['transmission_wrapper']['uid'] = 10006
node.default['transmission_wrapper']['gid'] = 10006

node.default['transmission_wrapper']['service_binary'] = 'transmission-daemon'
node.default['transmission_wrapper']['package'] = 'transmission-daemon'

node.override['iptables']['install_rules'] = false

node.default['openvpn_client']['dev'] = 'tun0'
node.default['openvpn_client']['run_options'] = ''
node.default['openvpn_client']['config_file'] = '$OPENVPN_CONF_NAME'
node.default['openvpn_client']['binary'] = '/usr/sbin/openvpn'

node.default['route']['networks'] = [
  '10.0.0.0/8',
  '172.16.0.0/12',
  '192.168.0.0/16',
  '169.254.0.0/16'
]
