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
  begin
    group new_resource.group do
      gid gid
      not_if { gid.nil? or gid < 1000 }
      action :nothing
    end.run_action(:create)
  rescue; end

  begin
    user new_resource.user do
      uid uid
      gid new_resource.group
      not_if { uid.nil? or uid < 1000 }
      action :nothing
    end.run_action(:create)
  rescue; end

  [new_resource.info_dir, settings['download-dir'], settings['incomplete-dir'], settings['watch-dir']].compact.each do |d|
    directory d do
      owner new_resource.user
      group new_resource.group
      recursive true
      action :nothing
    ## do not alter existing owner/rperms
    end.run_action(:create_if_missing)
    # end.run_action(:create)
  end

  file settings_file do
    content settings.to_json
    owner new_resource.user
    group new_resource.group
    action :nothing
  ## do not alter existing content or perm
  end.run_action(:create_if_missing)
  # end.run_action(:create)
end

##
## create runit service. run at build time
##

def transmission_service
  @transmission_service ||= runit_service new_resource.service do
    options(
      user: new_resource.user,
      daemon: node['transmission']['daemon'],
      info_dir: new_resource.info_dir
    )
    restart_on_update false
    action :nothing
  end
end

##
## get uid and gid of existing settings.json or info directory if available
##

def gid
  return Integer(ENV['GID'])
rescue
  return @gid unless @gid.nil?
  provided_owner
  return @gid
end

def uid
  return Integer(ENV['UID'])
rescue
  return @uid unless @uid.nil?
  provided_owner
  return @uid
end

def provided_owner
  if ::File.file?(settings_file)
    @uid = ::File.stat?(settings_file).uid
    @gid = ::File.stat?(settings_file).gid
  elsif ::File.directory?(new_resource.info_dir)
    @uid = ::File.stat?(new_resource.info_dir).uid
    @gid = ::File.stat?(new_resource.info_dir).gid
  end
end

##
## return settings.json file path - remove symlink if there is one.
##

def settings_file
  return @settings_file unless @settings_file.nil?
  @settings_file = ::File.join(new_resource.info_dir, 'settings.json')

  if ::File.symlink?(@settings_file)
    link @settings_file do
      action :nothing
    end.run_action(:delete)
  end
  return @settings_file
end

##
## return contents of settnigs.json - read mounted or make new.
##

def settings
  return @settings unless @settings.nil?

  ## read provided file
  if ::File.file?(settings_file)
    begin
      @settings = JSON.parse(::File.read(settings_file))
    rescue; end
  end

  ## populate if not provided
  if (@settings.nil? or @settings.empty?)
    new_resource.settings.each_pair do |k, v|
      case ENV[k]
      when nil
        ## no override
        @settings[k] = v
      when "true"
        ## boolean
        @settings[k] = true
      when "false"
        ## boolean
        @settings[k] = false
      else
        begin
          ## integer type
          @settings[k] = Integer(ENV[k])
        rescue
          ## string
          @settings[k] = ENV[k]
        end
      end
    end
  end
  return @settings
end




def action_build
  converge_by("Installing Transmission client #{new_resource.service}") do
    transmission_package.run_action(:install)
    transmission_service.run_action(:enable)
  end
end

def action_startup
  converge_by("Running Transmission client startup configuration #{new_resource.service}") do
    create_transmission_settings
  end
end
