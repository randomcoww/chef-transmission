node.override['chef_client']["daemon_options"] = ["-z", "-c", "/etc/chef/solo.rb", "-j", "/etc/chef/node.json"]

node.default['transmission']['packages'] = [
  'transmission-daemon',
  'nfs-common'
]
node.default['transmission']['daemon'] = '/usr/bin/transmission-daemon'
node.default['transmission']['nfs_mount_opts'] = 'rw,_netdev,hard,noatime,nodiratime'
