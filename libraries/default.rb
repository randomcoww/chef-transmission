module TransmissionWrapper
  module Helper
    include Chef::Mixin::ShellOut

    def default_gateway
      out = shell_out!('ip route list').stdout.lines.first
      out.gsub(/^default via (.*?) /) {
        return $1
      }
      return nil
    rescue
    end
  end
end
