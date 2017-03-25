execute "pkg_update" do
  command node['transmission']['pkg_update_command']
  action :run
end

package node['transmission']['pkg_names'] do
  action :upgrade
  notifies :stop, "service[transmission-daemon]", :immediately
end

transmission_config "transmission" do
  config node['transmission']['main']['config']
  action :create
  path '/var/lib/transmission-daemon/.config/transmission-daemon/settings.json'
  ## transmission writes the config at service stop.
  ## need to stop before writing the new config
  notifies :stop, "service[transmission-daemon]", :before
end

include_recipe "transmission::service"
