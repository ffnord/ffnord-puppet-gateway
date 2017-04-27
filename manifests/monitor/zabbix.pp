class ffnord::monitor::zabbix ( $zabbixserver
                              ) {

  apt::key {
    'zabbix-official-repo.key':
      key => '79EA5ED4',
      key_source => 'http://repo.zabbix.com/zabbix-official-repo.key';
  }

  apt::source {
    'zabbix':
      location   => 'http://repo.zabbix.com/zabbix/2.4/debian',
      release    => $::lsbdistcodename,
      repos      => 'main';
  }

  package {
    'zabbix-agent':
      ensure => installed,
      notify => Service['zabbix-agent'],
      require => [
        Apt::Source['zabbix']
      ];
  }

  service {
    'zabbix-agent':
      ensure => running,
      enable => true,
      require => [
        Package['zabbix-agent'],
      ];
  }

  file {
    '/etc/zabbix/zabbix_agentd.d/':
      ensure => directory,
      mode => '0755',
      owner => root,
      group => root,
      require => File['/etc/zabbix/zabbix_agentd.d/gw_monitoring.conf'];
    '/etc/zabbix/zabbix_agentd.d/gw_monitoring.conf':
      ensure  => file,
      content => "# managed by puppet
Server=${zabbixserver}
ServerActive=${zabbixserver}
HostnameItem=${::hostname}
",
      require => [
        Package['zabbix-agent'],
      ];
    '/opt/bin/':
      ensure => directory;
    '/opt/bin/zabbix/':
      ensure => directory,
      require => File['/opt/bin/'];
  }

  ffnord::firewall::service { 'zabbix':
    ports => ['10050'],
    source => $zabbixserver,
    chains => ['wan'];
  }
}

define ffnord::monitor::zabbix::check_script (
  $mesh_code = 'all',
  $scriptname,
  $sudo = false,
  $extra = '',
) {
  if defined(Class['ffnord::monitor::zabbix']) {

    if $sudo  {
      $sudo_cmd = 'sudo '

      ensure_resource('file', "/etc/sudoers.d/20_zabbix_${scriptname}", {
        'ensure' => 'file',
        'mode' => '0440',
        'owner' => 'root',
        'group' => 'root',
        'content' => inline_template("zabbix ALL= NOPASSWD: /opt/bin/zabbix/${scriptname}.sh\n"),
      })

    } else {
      $sudo_cmd = ''
    }

    file {
      "/etc/zabbix/zabbix_agentd.d/userparameter_${scriptname}_${mesh_code}.cfg":
        ensure => file,
        mode => '0644',
        owner => 'root',
        group => 'root',
        content => inline_template("UserParameter=${scriptname}_${mesh_code},${sudo_cmd}/opt/bin/zabbix/${scriptname}.sh ${mesh_code} ${extra}"),
        require => Package['zabbix-agent'],
        notify => Service['zabbix-agent'];
    }

    ensure_resource('file', "/opt/bin/zabbix/${scriptname}.sh", {
      'ensure' => 'file',
      'mode' => '0755',
      'source' => "puppet:///modules/ffnord/etc/zabbix/${scriptname}.sh"
    })
  }
}
