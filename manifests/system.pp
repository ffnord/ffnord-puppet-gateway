## Increase the conntracking default.
#
# For details have a look at
# https://github.com/jeffmurphy/NetPass/blob/master/doc/netfilter_conntrack_perf.txt
class ffnord::system::conntrack (
  $conntrack_max = 1048576,
  $conntrack_tcp_timeout = 1200,
  $conntrack_udp_timeout = 30
) {
  file {
    "/etc/sysctl.d/conntrack.conf":
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root',
      content => inline_template("net.netfilter.nf_conntrack_max=<%=conntrack_max%>/n");
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
