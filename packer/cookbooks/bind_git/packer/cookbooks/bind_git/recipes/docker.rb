bind_git_static "static_zones" do
  service_name "bind"
  user 'bind'
  group 'bind'
  git_repo ENV['GIT_REPO']
  git_branch ENV['GIT_BRANCH']
end

include_recipe 'chef-client::default'

## create startup script for phusion baseimage

file "/etc/my_init.d/95_chef_startup" do
  content(<<-EOF
#!/bin/bash
#{node['chef_client']['bin']} #{node['chef_client']['daemon_options'].join(' ')} -o bind_git::startup
EOF
  )
  mode '0755'
end
