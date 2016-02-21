transmission_container 'transmission' do
  action :install
end

include_recipe 'chef-client::default'
