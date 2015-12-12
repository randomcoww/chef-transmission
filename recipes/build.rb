transmission_container 'transmission' do
  action :build
end

## create startup script for phusion baseimage

file "/etc/my_init.d/95_chef_startup" do
  content(<<-EOF
#!/bin/bash
#{node['chef_client']['bin']} #{node['chef_client']['daemon_options'].join(' ')} -o transmission::startup
  EOF
  )
  mode '0755'
end
