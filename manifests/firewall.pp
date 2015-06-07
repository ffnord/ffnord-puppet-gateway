/** Simple and stupid firewall handling.
 *  
 * We simple define the firewall rules by putting them into ordered files.
 * This way we can place new rules at any position into the chains.
 * 
 * The general processing idea is to define a zone for each device handled
 * and define which zones are allowed to forward traffic trough this device.
 * According to the device definition forwarding packages may be handled
 * by connection tracking. Traffic from a zone is then processed
 * through a zone forward chain and pre-filtered before passed to the
 * destination device chain.
 * 
 * We have four zones in this setup: mesh, uplink, icvpn, peering.
 * Each with a forward input, forward output and a input chain, e.g: 
 *   mesh-fwd-in, mesh-fwd-out and mesh-input.
 * 
 * The order of execution is matched to meaning by the following list:
 * 
 * 000 RESET all the rules
 * 025 Pre conntrack forward handling
 * 050 Connection Tracking
 * 100 Zone selection
 * 500+ Service/Port acceptance
 * 700 Zone-Device forwarding handling
 * 850 Forwarding acceptance
 * 900 Drop the rest
 * 900+ Mangle/Postrouting handling
 *
 * ATTENTION: The firewall rules will not triggered by this class.
 *            You have to invoke the build-firewall script yourself.
 * 
 */

class ffnord::firewall (
  $wan_devices = $ffnord::params::wan_devices
) inherits ffnord::params {

  include ffnord::resources::rclocal

  package { 
    'iptables-persistent':
      ensure => installed;
    'iptables':
      ensure => installed;
  }

  service {
    'iptables-persistent':
       ensure => running,
       hasrestart => true,
       enable => true,
       require => Package['iptables-persistent'];
  }

  file { 
    '/etc/iptables.d/': 
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';
    '/usr/local/bin/build-firewall':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0755',
      source => "puppet:///modules/ffnord/usr/local/bin/build-firewall";
    '/etc/iptables.d/000-RESET': 
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/000-RESET",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/001-CHAINS':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/001-CHAINS",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/050-FORWARD-PreProcessing': 
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/050-FORWARD-PreProcessing",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/050-INPUT-PreProcessing': 
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/050-INPUT-PreProcessing",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/200-block-ranges':
      ensure => file,
      replace => 'no', # Don't replace local changes in this file
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/200-block-ranges",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/200-block-bcp38':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/200-block-bcp38",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/500-Allow-SSH':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/500-Allow-SSH",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/900-FORWARD-drop':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/900-FORWARD-drop",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/900-INPUT-drop':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/900-INPUT-drop",
      require => File['/etc/iptables.d/'];
    '/etc/iptables.d/900-LOG-drop':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/900-LOG-drop",
      require => File['/etc/iptables.d/'];
  }

  ffnord::monitor::zabbix::check_script {
    "ip_conntrack_count":
      scriptname => "ip_conntrack_count";
    "ip_conntrack_max":
      scriptname => "ip_conntrack_max";
  }

  ffnord::firewall::device { $wan_devices:
    zone => 'wan',
    inter_zone_forward => false,
    forward_conntrack => true;
  }
}

define ffnord::firewall::service (
 $protos = ["tcp"],  # Possible values "tcp,udp,gre"
 $chains = ["mesh"], # Possible values "mesh,wan"
 $ports = [],
 $source = undef,
 $rate_limit = false, # rate limit
 $rate_limit_seconds  = 60, # rate limit Seconds
 $rate_limit_hitcount = 10 # rate limit hitcount
) {

 file { "/etc/iptables.d/500-Allow-${name}":
   ensure => file,
   owner => "root",
   group => "root",
   mode => "0644",
   content => inline_template("# Allow Service <%=@name%>
<% @chains.each do |chain| -%>
<% @protos.each do |proto| -%>
<% if @ports.length > 0 -%>
<% @ports.each do |port| -%>
<% if @rate_limit -%>
rate_limit46 \"<%=@name%>\" <%=@rate_limit_seconds%> <%=@rate_limit_hitcount%> -A <%=chain%>-input -p <%=proto%> -m <%=proto%> --dport <%=port%><% if @source -%> -s <%=@source%>
<% end %>
<% end -%>
ip46tables -A <%=chain%>-input -p <%=proto%> -m <%=proto%> --dport <%=port%><% if @source -%> -s <%=@source%><% end -%> -j ACCEPT -m comment --comment '<%=@name%>'
<% end -%>
<% else %>
ip46tables -A <%=chain%>-input -p <%=proto%><% if @source -%> -s <%=@source%><% end -%> -j ACCEPT -m comment --comment '<%=@name%>'
<% end -%>
<% end -%>
<% end -%>
");
 }
}

# Process packages from devices
define ffnord::firewall::device (
  $zone = "mesh",  # Possible values are "mesh","wan","uplink","icvpn"
  $zone_forward_ipv4 = [], # which zones are allowed to forward ipv4 traffic through this device
  $zone_forward_ipv6 = [], # which zones are allowed to forward ipv6 traffic through this device 
  $inter_zone_forward = true, 
  $forward_conntrack,  # shall forwarded traffic be handled by connection tracking
) {

  include ffnord::firewall

  # 002 - Define device specific chain, for forwarded output.
  #       ZONE-fwd-INTERFACENAME-out
  if size($zone_forward_ipv4) + size($zone_forward_ipv6) > 0 or $inter_zone_forward {
    file { "/etc/iptables.d/002-device-chains-${name}": 
      ensure => file,
      owner => "root",
      group => "root",
      mode => "0644",
      content => inline_template("# Allow zone forwarding for device <%=@name%>
ip46tables -N <%=@zone%>-fwd-<%=@name%>-out
"),
      require => [File['/etc/iptables.d/']];
    }
  }

  # 025 - When traffic should not be handled by connection tracking we have to jump
  #       it directly to the fwd-in chain, for further processing.
  if ! $forward_conntrack {
    file { "/etc/iptables.d/025-forward-device-${name}":
      ensure => "file",
      owner => "root",
      group => "root",
      mode => "0644",
      content => inline_template("# Jump packages to the forward-in chain before conntrack
ip46tables -A FORWARD -i <%=@name%> -j fwd-in
")
    }
  }

  # 100 - Jump packages to zone chains.
  file { "/etc/iptables.d/100-device-${name}": 
    ensure => file,
    owner => "root",
    group => "root",
    mode => "0644",
    # instead of the chain-fwd-out we shall jump to chain-fwd-in and check for e.g. source
    content => inline_template("# Process packages from device <%=@name%>
ip46tables -A input -i <%=@name%> -j <%=@zone%>-input
<% if @inter_zone_forward -%>
# Inter-Zone-Traffic is allowed for this device.
ip46tables -A fwd-in -i <%=@name%> -j <%=@zone%>-fwd-<%=@name%>-out
<% end -%>
"),
    require => [File['/etc/iptables.d/']];
  }

  file { "/etc/iptables.d/800-${chain}-forward-ACCEPT-${name}": 
    ensure => absent;
  }

  # 700 - Accepting packages from other zones, for the device specific output chain.
  if size($zone_forward_ipv4) + size($zone_forward_ipv6) > 0 or $inter_zone_forward {
    file { "/etc/iptables.d/700-forward-transfer-${name}": 
      ensure => file,
  	  owner => "root",
      group => "root",
      mode => "0644",
      content => inline_template("# Process packages to device <%=@name%>
<% @zone_forward_ipv4.each do |zone_ipv4| -%>
ip4tables -A <%=zone_ipv4%>-fwd-in -o <%=@name%> -j <%=@zone%>-fwd-<%=@name%>-out
<% end -%>
<% @zone_forward_ipv6.each do |zone_ipv6| -%>
ip4tables -A <%=zone_ipv6%>-fwd-in -o <%=@name%> -j <%=@zone%>-fwd-<%=@name%>-out
<% end -%>
"),
  	  require => [File['/etc/iptables.d/']];
    }
  }

  # 850 - Accept all remaining packages on the device specific output chain.
  if size($zone_forward_ipv4) + size($zone_forward_ipv6) > 0 or $inter_zone_forward {
    file { "/etc/iptables.d/850-${chain}-forward-ACCEPT-${name}": 
  	  ensure => file,
  	  owner => "root",
  	  group => "root",
  	  mode => "0644",
  	  content => inline_template("# Finally accept all remaining forward packages for <%=@name%>
ip46tables -A <%=@zone%>-fwd-<%=@name%>-out -j ACCEPT
"),
      require => [File['/etc/iptables.d/']];
    }
  }
}

define ffnord::firewall::set_value(
  $path,
  $value,
) {

 file { "/etc/iptables.d/000-file-value-${name}": 
   ensure => file,
   owner => "root",
   group => "root",
   mode => "0644",
   content => inline_template("set_value ${path} ${value}\n"),
   require => [File['/etc/iptables.d/']];
 }
}
