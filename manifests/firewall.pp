/** Simple and stupid firewall handling.
 *  
 * We simple define the firewall rules by putting them into ordered files.
 * This way we can place new rules at any position into the chains.
 * The predefined ruleset first resets the Xtables rulesets and 
 * handles connection tracking, jumping the packages into seperated
 * chains or directly drop them. 
 * Packages accepted for further processing are then be sorted into
 * zone specific chaines. 
 * 
 * We have two zones in this setup: mesh and wan
 * Each with a forward and a input chain: mesh-forward, mesh-input, ...
 * 
 * The order of execution is matched to meaning by the following list:
 * 
 * 000 RESET all the rules
 * 001 Preprocessing
 * 100 Zone selection
 * 500+ Service/Port acceptance
 * 800 Forwarding acceptance
 * 900 Drop the rest
 * 900+ Mangle/Postrouting handling
 *
 * ATTENTION: The firewall rules will not triggered by this class.
 *            You have to invoke the build-firewall script yourself.
 * 
 */

class ffnord::firewall {

  file { 
    '/etc/iptables.d/': 
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755';
  }

  file {
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
      source => "puppet:///modules/ffnord/etc/iptables.d/000-RESET";
    '/etc/iptables.d/001-FORWARD-PreProcessing': 
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/001-FORWARD-PreProcessing";
    '/etc/iptables.d/001-INPUT-PreProcessing': 
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/001-INPUT-PreProcessing";
    '/etc/iptables.d/500-Allow-SSH':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/500-Allow-SSH";
    '/etc/iptables.d/900-FORWARD-drop':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/900-FORWARD-drop";
    '/etc/iptables.d/900-INPUT-drop':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0644',
      source => "puppet:///modules/ffnord/etc/iptables.d/900-INPUT-drop";
  }
}

define ffnord::firewall::service (
 $protos = ["tcp"],  # Possible values "tcp,udp"
 $chains = ["mesh"], # Possible values "mesh,wan"
 $ports = [],
) {
 file { "/etc/iptables.d/500-Allow-${name}": 
   ensure => file,
   owner => "root",
   group => "root",
   mode => "0644",
   content => inline_template("# Allow Service <%=@name%>
<% @chains.each do |chain| -%>
<% @protos.each do |proto| -%>
<% @ports.each do |port| -%>
ip46tables -A <%=chain%>-input -p <%=proto%> -m <%=proto%> --dport <%=port%> -j ACCEPT
<% end -%>
<% end -%>
<% end -%>
");
 }
}

# Process packages from devices into the chains
define ffnord::firewall::device (
  $chain = "mesh" # Possible values are "mesh","wan"
) {
 file { "/etc/iptables.d/100-device-${name}": 
   ensure => file,
   owner => "root",
   group => "root",
   mode => "0644",
   content => inline_template("# Process packages from device <%=@name%>
ip46tables -A input -i <%=@name%> -j <%=@chain%>-input
ip46tables -A forward -i <%=@name%> -j <%=@chain%>-forward
");
 }
}

# Allow device for mesh forwarding
define ffnord::firewall::forward (
  $chain = "mesh" # Possible values are "mesh","wan"
) {
 file { "/etc/iptables.d/800-${chain}-forward-ACCEPT-${name}": 
   ensure => file,
   owner => "root",
   group => "root",
   mode => "0644",
   content => inline_template("# Process packages from device <%=@name%>
ip46tables -A mesh-forward -o <%=@name%> -j ACCEPT
");
 }
}
