class ChefTransmission
  class Provider
    class Config < Chef::Provider
      provides :transmission_config, os: "linux"

      def load_current_resource
        @current_resource = ChefTransmission::Resource::Config.new(new_resource.name)

        current_resource.exists(::File.exist?(new_resource.path))

        if current_resource.exists
          current_resource.config(JSON.parse(::File.read(new_resource.path)))
        else
          current_resource.config({})
        end

        current_resource
      end

      def action_create_if_missing
        converge_by("Create Transmission config: #{new_resource}") do
          transmission_config.run_action(:create_if_missing)
        end if !current_resource.exists
      end

      def action_create
        converge_by("Create Transmission config: #{new_resource}") do
          transmission_config.run_action(:create)
        end if !current_resource.exists || new_config != current_resource.config
      end

      def action_delete
        converge_by("Delete Transmission config: #{new_resource}") do
          transmission_config.run_action(:delete)
        end if current_resource.exists
      end

      private

      def new_config
        @new_config ||= current_resource.config.merge(new_resource.config.to_hash)
      end

      def transmission_config
        @transmission_config ||= Chef::Resource::File.new(new_resource.path, run_context).tap do |r|
          r.path new_resource.path
          r.content new_config.to_json
        end
      end
    end
  end
end
