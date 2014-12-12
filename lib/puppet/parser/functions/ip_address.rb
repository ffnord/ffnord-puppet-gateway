#
# ip_address.rb
#

module Puppet::Parser::Functions
  newfunction(:ip_address, :type => :rvalue, :doc => <<-EOS
    Returns the address of an IPv{4,6} address, where the given address is in
    cidr notation, e.g. 192.168.0.1/16 results in 192.168.0.1.
  EOS
  ) do |args|
    ip_address =args[0]
    return ip_address.split('/')[0]
  end
end
