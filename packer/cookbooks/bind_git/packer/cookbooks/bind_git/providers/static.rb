require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def load_current_resource
  @current_resource = Chef::Resource::BindGitStatic.new(new_resource.name)
  @current_resource 
end





def bind_package
  return @bind_package unless @bind_package.nil?

  @bind_package = package new_resource.bind_package do
    action :nothing
  end

  return @bind_package
end

def bind_service
  return @bind_service unless @bind_service.nil?

  @bind_service = runit_service new_resource.service_name do
    options(
      :user => new_resource.user
    )
    restart_on_update false
    action :nothing
  end

  return @bind_service
end

def named_conf
  return @named_conf unless @named_conf.nil?

  @named_conf = template "#{new_resource.name}_named_conf" do
    path ::File.join(new_resource.conf_path, 'named.conf')
    source new_resource.named_conf_template
    mode '0644'
    owner new_resource.user
    group new_resource.group
    cookbook new_resource.named_conf_cookbook
    variables ({
      'zone_conf_name' => new_resource.zone_conf_name,
      'conf_path' => new_resource.conf_path,
      'zone_path' => new_resource.deploy_to,
    }.merge(new_resource.named_conf_variables))
    ## no config changes for chef local mode
    #notifies :restart, "service[#{new_resource.service_name}]", :delayed
    action :nothing
  end

  return @named_conf
end

def git_hash
  begin
    out = shell_out!("git rev-parse HEAD",
      :cwd => new_resource.deploy_to,
      :user => new_resource.user,
      :group => new_resource.group
    )

    return out.stdout.chomp
  rescue
    return ""
  end
end

def git_repo
  return @git_repo unless @git_repo.nil?

  @old_git_hash = git_hash

  directory ::File.dirname(new_resource.deploy_to) do
    owner new_resource.user
    group new_resource.group
    recursive true
    action :nothing
  end.run_action(:create)

  @git_repo = git "#{new_resource.name}_repo" do
    repository new_resource.git_repo
    revision new_resource.git_branch

    user new_resource.user
    group new_resource.group

    destination new_resource.deploy_to

    action :nothing
    not_if { new_resource.git_repo.nil? or new_resource.git_branch.nil? }
  end

  return @git_repo
end

def git_changes
  return @git_changes unless @git_changes.nil?
  
  @git_changes = []

  if git_repo.updated_by_last_action?
    out = shell_out!("git diff --name-only #{@old_git_hash} #{git_hash}",
      :cwd => new_resource.deploy_to,
      :user => new_resource.user,
      :group => new_resource.group
    )

    @git_changes = out.stdout.lines.map { |k|
      next if k.chars.first == '.'
      k.chomp
    } || []
  end

  return @git_changes
end

def git_reset
  if git_repo.updated_by_last_action?
  
    shell_out!("git reset --hard #{@old_git_hash}",
      :cwd => new_resource.deploy_to,
      :user => new_resource.user,
      :group => new_resource.group
    )
  end
end

def zone_conf
  return @zone_conf unless @zone_conf.nil?

  added_zones = {}

  ## check for added or missing files
  if ::File.directory?(new_resource.deploy_to)

    ::Dir.entries(new_resource.deploy_to).each do |p|
      next if p.chars.first == '.'
      next unless ::File.file?(::File.join(new_resource.deploy_to, p))
      added_zones[p] = true
    end
  end

  #zone_conf(added_zones.keys).run_action(:create)
  @zone_conf = template "#{new_resource.name}_zone_conf" do
    path ::File.join(new_resource.conf_path, new_resource.zone_conf_name)
    source new_resource.zone_conf_template
    mode '0644'
    owner new_resource.user
    group new_resource.group
    cookbook new_resource.zone_conf_cookbook
    variables ({ 'zones' => added_zones.keys.sort.uniq }.merge(new_resource.zone_conf_variables))
    action :nothing
  end

  return @zone_conf
end

def reload
  shell_out!("/usr/sbin/rndc reconfig") if (zone_conf.updated_by_last_action? or named_conf.updated_by_last_action?)

  git_changes.each do |z|

    ## don't try to reload if file was deleted
    zone_file = ::File.join(new_resource.deploy_to, z)
    next unless ::File.file?(zone_file)

    out = shell_out!("named-checkzone #{z} #{zone_file}")
    puts out.stdout

    out = shell_out!("/usr/sbin/rndc reload #{z}")
    puts out.stdout
  end
end






##
## actions
##

def action_create
  converge_by("Create BIND confs") do
    
    bind_package.run_action(:install)
    named_conf.run_action(:create)
    git_repo.run_action(:sync)
    zone_conf.run_action(:create)
    
    bind_service.run_action(:enable)
    #bind_service.run_action(:start)

    begin
      reload

    rescue
      if git_repo.updated_by_last_action?
        Chef::Log.error("Failed to reload new configs. Reverting")
        git_reset
        zone_conf.run_action(:create)

        reload
      end
    end
  end
end

##
## startup actions
##
## this can be run as a startup script before runit is ready.
## initial servicre startup happens after this.
##

def action_startup
  converge_by("Initialize BIND resources") do

    named_conf.run_action(:create)
    git_repo.run_action(:sync)
    zone_conf.run_action(:create)
  end
end
