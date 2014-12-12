#
# ip_netmask.rb
#

module Puppet::Parser::Functions
  newfunction(:ip_netmask, :type => :rvalue, :doc => <<-EOS
    Returns the network mask of an IPv{4,6} address. The given
    address must be in cidr notation. Using an netmask for IPv6 is
    unusual but some tools require such, e.g. ntpd. Examples:

     * 192.168.0.1/24 results in 255.255.255.0
     * 2001:db8::/64 results in ffff:ffff:ffff:ffff::
  EOS
  ) do |args|
    ip_address = args[0]
    if IPAddr.new(ip_address).ipv6?()
      net = IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff')
      return net.mask(ip_address).to_string()
    else
      net = IPAddr.new('255.255.255.255')
      return net.mask(ip_address).to_string()
    end
  end
end
