class ffnord::monitor::vnstat () {
  package { 'vnstat' : ensure => installed; }
}

define ffnord::monitor::vnstat::device() {
  include ffnord::monitor::vnstat
 
  Package['vnstat']
  -> exec { "vnstat device ${name}":
           command => "/usr/bin/vnstat -u -i ${name}";
       }
}
