## Increase the conntracking default.
#
# For details have a look at
# https://github.com/jeffmurphy/NetPass/blob/master/doc/netfilter_conntrack_perf.txt
class ffnord::system::conntrack (
  $conntrack_max = 1048576,
) {
  file {
    "/etc/sysctl.d/conntrack.conf":
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root', 
      content => inline_template("net.netfilter.nf_conntrack_max=<%=conntrack_max%>/n");
    "/etc/modules/nf_conntrack":
      ensure => file,
      mode => '0644',
      owner => 'root',
      group => 'root', 
      content => inline_template("options nf_conntrack hashsize=<%=conntrack_max%>/n");
  }
}
