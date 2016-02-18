node.override['chef_client']["daemon_options"] = ["-z", "-c", "/etc/chef/solo.rb", "-j", "/etc/chef/node.json"]

node.default['transmission']['packages'] = [
  'transmission-daemon'
]
node.default['transmission']['daemon'] = '/usr/bin/transmission-daemon'
