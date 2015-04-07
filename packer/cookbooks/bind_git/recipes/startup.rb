bind_git_static "static_zones" do
  service_name "bind"
  user 'bind'
  group 'bind'
  git_repo ENV['GIT_REPO']
  git_branch ENV['GIT_BRANCH']
  deploy_to '/var/lib/bind/repo'

  action :startup
end
