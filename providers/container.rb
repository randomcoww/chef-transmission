def load_current_resource
  @current_resource = Chef::Resource::TransmissionContainer.new(new_resource.service)
  @current_resource
end




##
## run at build
##

def transmission_package
  @transmission_package ||= package node['transmission']['package'] do
    action :nothing
  end
end

##
## run at startup
##

def create_transmission_settings
  ## create directories if not supplied - do not change permissions if it already exists
  [new_resource.info_dir, settings['download-dir'], settings['incomplete-dir'], settings['watch-dir']].compact.each do |d|
    directory d do
      owner new_resource.user
      group new_resource.group
      recursive true
      action :nothing
    end.run_action(:create_if_missing)
  end

  ## reconfigure user to match uid/gid of directories
  group new_resource.group do
    gid ::File.stat(new_resource.info_dir).gid
    action :nothing
  end.run_action(:create)

  user new_resource.user do
    uid ::File.stat(new_resource.info_dir).uid
    gid new_resource.group
    action :nothing
  end.run_action(:create)

  ## settings.json
  settings_file = ::File.join(new_resource.info_dir, 'settings.json')

  ## remove if symlink. replace with file
  link settings_file do
    action :nothing
  end.run_action(:delete)

  file settings_file do
    content settings.to_json
    owner new_resource.user
    group new_resource.group
    action :nothing
  end.run_action(:create_if_missing)
end

##
## run at build or startup
##

def transmission_service
  @transmission_service ||= runit_service new_resource.service do
    options(
      user: new_resource.user,
      service_binary: node['transmission']['daemon'],
      info_dir: new_resource.info_dir
    )
    restart_on_update false
    action :nothing
  end
end

##
## helper
##

def settings
  return @settings unless @settings.nil?
  @settings = {}
  new_resource.settings.each_pair do |k, v|
    if ENV.has_key?(k)
      @settings[k] = ENV[k]
    else
      @settings[k] = v
    end
  end
  return @settings
end




def action_build
  transmission_package.run_action(:install)
  transmission_service.run_action(:enable)
end

def action_startup
  create_transmission_settings
end
