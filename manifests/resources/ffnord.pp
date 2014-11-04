# Ensure existence of global configuration file
# for various scripts from this module.
class ffnord::resources::ffnord {
  file { '/etc/ffnord':
    ensure => file,
    mode => "0644";
  }
}

# Define new configuration keys and set a 
# default value. Because stdlib::file_line 
# can only match and then replace, but not
# search and if not exists insert, calling
# this value will always write the default
# value.
define ffnord::resources::ffnord::field(
  $value = ''
) { 
  include ffnord::resources::ffnord

  file_line { "${name}":
      path => '/etc/ffnord',
      match => "^${name}=.*",
      line => "${name}=${value}";
  }
}
