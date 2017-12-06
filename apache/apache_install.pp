class apache::install inherits apache {

  package { 'apache':
    ensure => installed,
  }

}
