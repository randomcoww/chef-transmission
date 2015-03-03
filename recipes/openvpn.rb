bag = Chef::EncryptedDataBagItem.load('openvpn', 'pia_seattle')

openvpn_client_service 'pia_seattle' do
  config ({
    "dev" => node['openvpn_client']['dev'],
    "proto" => "udp",
    "remote" => "#{bag['url']} 1194",
    "resolv-retry" => "infinite",
    "nobind" => nil,
    "persist-key" => nil,
    "tls-client" => nil,
    "remote-cert-tls" => "server",
    "comp-lzo" => nil,
    "verb" => "3",
    "reneg-sec" => "0",
    "cipher" => "BF-CBC",
    "keepalive" => "10 30",
    "route-nopull" => nil,
    "redirect-gateway" => nil,
    "fast-io" => nil,
  })
  auth_user bag['user']
  auth_pass bag['password']
  ca bag['ca']
end
