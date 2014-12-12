#
# ip_prefix.rb
#

module Puppet::Parser::Functions
  newfunction(:ip_prefix, :type => :rvalue, :doc => <<-EOS
    Returns the routing prefix or network of an IPv{4,6} address. The given
    address must be in cidr notation, e.g. 192.168.0.1/24 results in 192.168.0.0.
  EOS
  ) do |args|
    ip_address = args[0]
    return IPAddr.new(ip_address).to_string()
  end
end
