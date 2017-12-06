class apache::service inherits apache {

  service { 'apache':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require => Package['apache'],
  }

}
