module Vault
  module Rails
    module Serializers
      # Converts IPAddr objects to and from strings
      module IPAddrSerializer
        module_function

        def encode(ip_addr)
          return nil if ip_addr.blank?

          "#{ip_addr}/#{ip_addr.instance_variable_get(:@mask_addr).to_s(2).count('1')}"
        end

        def decode(string)
          return nil if string.blank?
          IPAddr.new(string)
        end
      end
    end
  end
end
