#
# ip_prefixlen.rb
#

module Puppet::Parser::Functions
  newfunction(:ip_prefixlen, :type => :rvalue, :doc => <<-EOS
    Returns the prefix length of an IPv{4,6} address. The given 
    address must be in cidr notation, e.g. 192.168.0.1/24 results in 24.
  EOS
  ) do | args|
    ip_address = args[0]
    return ip_address.split('/')[1]
  end
end
