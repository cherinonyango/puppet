class apache::config inherits apache {

  file { '/etc/apache.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    content => template($module_name/apache.conf.erb),
  }

}
