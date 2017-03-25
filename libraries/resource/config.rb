class ChefTransmission
  class Resource
    class Config < Chef::Resource
      include Transmission

      resource_name :transmission_config

      default_action :create
      allowed_actions :create, :create_if_missing, :delete

      property :exists, [TrueClass, FalseClass]
      property :config, Hash
      property :path, String, desired_state: false,
                              default: lazy { Transmission::CONFIG_PATH }
    end
  end
end
