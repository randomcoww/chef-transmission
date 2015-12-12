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
  ## try to reconfigure uid/gid to match that of mounted directory (if any)
  # if ::File.file?(new_resource.info_dir)
  #   begin
  #     gid = ::File.stat(new_resource.info_dir).gid
  #     group new_resource.group do
  #       gid gid
  #       not_if { gid < 1000 }
  #       action :nothing
  #     end.run_action(:create)
  #   rescue; end
  #
  #   begin
  #     uid ::File.stat(new_resource.info_dir).uid
  #     user new_resource.user do
  #       uid uid
  #       gid new_resource.group
  #       not_if { uid < 1000 }
  #       action :nothing
  #     end.run_action(:create)
  #   rescue; end
  # end

  ## create directories if not supplied - do not change permissions if it already exists
  [new_resource.info_dir, settings['download-dir'], settings['incomplete-dir'], settings['watch-dir']].compact.each do |d|
    directory d do
      owner user
      recursive true
      action :nothing
    end.run_action(:create_if_missing)
  end

  ## settings.json
  settings_file = ::File.join(new_resource.info_dir, 'settings.json')

  ## remove if symlink. replace with file
  link settings_file do
    action :nothing
  end.run_action(:delete)

  file settings_file do
    content settings.to_json
    owner user
    # group group
    action :nothing
  end.run_action(:create_if_missing)
end

##
## run at build or startup
##

def transmission_service
  @transmission_service ||= runit_service new_resource.service do
    options(
      user: user,
      daemon: node['transmission']['daemon'],
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
    case ENV[k]
    when nil
      @settings[k] = v
    when "true"
      @settings[k] = true
    when "false"
      @settings[k] = false
    else
      @settings[k] = ENV[k]
    end
  end
  return @settings
end

def user
  return @user unless @user.nil?
  @user = new_resource.user

  if ::File.file?(new_resource.info_dir)
    begin
      gid = ::File.stat(new_resource.info_dir).gid
      group new_resource.group do
        gid gid
        not_if { gid < 1000 }
        action :nothing
      end.run_action(:create)
    rescue; end

    begin
      uid ::File.stat(new_resource.info_dir).uid
      user @user do
        uid uid
        gid new_resource.group
        not_if { uid < 1000 }
        action :nothing
      end.run_action(:create)
    rescue; end

    return @user
  end
end




def action_build
  transmission_package.run_action(:install)
  transmission_service.run_action(:enable)
end

def action_startup
  create_transmission_settings
end
