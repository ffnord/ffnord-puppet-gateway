class ffnord::etckeeper {

  # Ensure the gitignore file exists befor we put our own lines into it
  file {
    '/etc/.gitignore':
      ensure => file,
      owner => 'root',
      group => 'root',
      mode => '0600';
  } ->

  # Ensure that we do not track the ffnord module
  file_line {
    'etckeeper_puppet':
       path => '/etc/.gitignore',
       line => 'puppet/modules/ffnord/';
    'etckeeper_dotfiles':
       path => '/etc/.gitignore',
       line => '.*';
  } ->

  package {
    'etckeeper':
       ensure => installed;
  }
}

# Create an gitignore entry for given path
define ffnord::etckeeper::ignore {
  if defined(Class['ffnord::etckeeper']) {
    validate_absolute_path($name)
    # Does path $name begin with '/etc/'
    if $name =~ /^\/etc\// {
      $ignore = regsubst($name,'^/etc/(.*)$','\1')
      file_line {
        "etckeeper_${name}":
          path => '/etc/.gitignore',
          line => $ignore,
          before => Package['etckeeper'];
      }
    }
  }
}
