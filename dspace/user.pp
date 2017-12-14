class dspace::owner ($username = 'Dspace',
                      $gid = $username,
                      $groups = undef,
                      $sudoer = false,
                      $authorized_keys_source = "puppet:///modules/dspace/ssh_authorized_keys",
                      $maven_opts = '-Xmx512m',
                      $ensure = 'present')
{
include stdlib

  case $ensure
  {

    # Present = Create User & Initialize
    present: {

      # Ensure the user's group exists (if not, create it)
      group { $gid:
        ensure => present,
      }
# create user
user { $username :
  ensure     => 'present',
  home       => '/home/$username',
  comment    => $username,
  groups     => $group,
  managehome => true,
  password   => '!',
  shell      => '/bin/bash',
}

# Make sure they have a home with proper permissions.
file { "/home/${username}":
   ensure  => directory,
   owner   => $username,
   group   => $gid,
   mode    => '0750',
   require => User[$username],
}
