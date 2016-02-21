transmission_container 'transmission' do
  action :build
end

include_recipe 'chef-client::default'
