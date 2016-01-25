## Increase the conntracking default.
#
# For details have a look at
# https://github.com/jeffmurphy/NetPass/blob/master/doc/netfilter_conntrack_perf.txt
class ffnord::system::conntrack (
  $conntrack_max = $ffnord::params::conntrack_max,
  $conntrack_tcp_timeout = $ffnord::params::conntrack_tcp_timeout,
  $conntrack_udp_timeout = $ffnord::params::conntrack_udp_timeout,
  $wmem_default = $ffnord::params::wmem_default,
  $wmem_max = $ffnord::params::wmem_max,
  $rmem_default = $ffnord::params::rmem_default,
  $rmem_max = $ffnord::params::rmem_max,
  $max_backlog = $ffnord::params::max_backlog,
) inherits ffnord::params {
  file {
    "/etc/sysctl.d/conntrack.conf":
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      content => inline_template("net.netfilter.nf_conntrack_max=<%=@conntrack_max%>\n");
  }

  exec {
    'sysctl load conntrack.conf':
     command => "/sbin/sysctl -p /etc/sysctl.d/conntrack.conf",
     require => File['/etc/sysctl.d/conntrack.conf'];
  }

  file {
    "/etc/sysctl.d/routing.conf":
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      content => template("ffnord/etc/sysctl.d/routing.conf");
  }

  exec {
    'sysctl load routing.conf':
     command => "/sbin/sysctl -p /etc/sysctl.d/routing.conf",
     require => File['/etc/sysctl.d/routing.conf'];
  }

  ffnord::firewall::set_value {
    "conntrack_max":
      path  => "/sys/module/nf_conntrack/parameters/hashsize",
      value => $conntrack_max;
  }
}
