class dspace {

file {
    'dspace.sh':
      ensure => 'file',
       source => '/etc/puppet/modules/dspace/manifests/dspace.sh',
      path => '/etc/puppet/modules/dspace/manifests/dspace.sh',
      owner => 'root',
      group => 'root',
      mode  => '0755', # Use 0700 if it is sensitive
      notify => Exec['dspace.sh'],
  }
exec {
    'dspace.sh':
  command => "/bin/bash -c 'dspace.sh'",
  }
}

