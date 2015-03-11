class ffnord::resources::rclocal () {

   file {
     "/etc/rc.local":
       ensure => file,
       owner => "root",
       group => "root",
       mode => "0755",
       source => "puppet:///modules/ffnord/etc/rc.local";
     "/etc/rclocal.d":
       ensure => directory,
       owner => "root",
       group => "root",
       mode => "0755";
   }
}
