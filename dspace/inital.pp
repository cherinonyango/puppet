class dspace(
$owner	= 'dspace',
$group	= 'dspace',
$ $src_dir  = "/etc/puppetlabs/code/environments/production/modules/dspace/dspace-src",
$install_dir = "/etc/puppetlabs/code/environments/production/modules/dspace/dspace",
$installer_dir_name = 'dspace-installer',
$git_repo = 'https://github.com/DSpace/DSpace.git',
$git_branch        = 'puppet',
$mvn_params        = '',
$ant_installer_dir = $dspace::installer_dir_name,
$port              = 8080,
$db_name           = 'dspace',
$db_port           = 5432,
$db_user           = 'dspace',
$db_passwd         = 'dspace12',
$handle_prefix     = '123456789',
$local_config_source = undef,
$ensure = present)

{
$ant_installer_path = "${src_dir}/dspace/target/${ant_installer_dir}"
 file { "${install_dir}":
        ensure => "directory",
        owner  => $owner,
        group  => $group,
        mode   => 0700,
}
->
  # if the src_dir folder does not yet exist, create it
file { "${src_dir}":
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => 0700,
    }

->
 exec { "Adding the fingerprint for GitHub so we can connect to it":
        command   => "ssh -T -oStrictHostKeyChecking=no git@github.com",
        returns   => [0,1],
        user      => $owner,
        logoutput => true,
    }

->

    exec { "Cloning DSpace source code into ${src_dir}":
        command   => "git init && git remote add origin ${git_repo} && git fetch --all && git checkout -B master origin/master",
        creates   => "${src_dir}/.git",
        user      => $owner,
        cwd       => $src_dir, # run command from this directory
        logoutput => true,
        tries     => 4,    # try 4 times
        timeout   => 1200, # set a 20 min timeout. DSpace source is big which could be slow on some connections
    }
 ### End of Dspace Clone
->
 exec { "Checkout branch ${git_branch}" :
       command => "git checkout ${git_branch}",
       cwd     => $src_dir, # run command from this directory
       user    => $owner,
       # Only perform this checkout if the branch EXISTS and it is NOT currently checked out (if checked out it will have '*' next to it in the branch listing)
       onlyif  => "git branch -a | grep -w '${git_branch}' && git branch | grep '^\\*' | grep -v '^\\* ${git_branch}\$'",
    }
->

  file { "${src_dir}/custom.properties":
     ensure  => file,
     owner   => $owner,
     group   => $group,
     mode    => 0644,
     content => template("dspace/custom.properties.erb"),
}

  if $local_config_source {
     # Initialize local.cfg from provided source file
     file { "${src_dir}/dspace/config/local.cfg":
       ensure  => file,
       owner   => $owner,
       group   => $group,
       mode    => 0644,
       source  => $local_config_source,
       require => Exec["Checkout branch ${git_branch}"],
       before  => Exec["Build DSpace installer in ${src_dir}"],
     }
   }
   else {
     # Create a 'local.cfg' file from our default template
     file { "${src_dir}/dspace/config/local.cfg":
       ensure  => file,
       owner   => $owner,
       group   => $group,
       mode    => 0644,
       content => template("dspace/local.cfg.erb"),
       require => Exec["Checkout branch ${git_branch}"],
       before  => Exec["Build DSpace installer in ${src_dir}"],
     }

   }


   # Build DSpace installer.
   # (NOTE: by default, $mvn_params='-Denv=custom', which tells Maven to use the custom.properties file created above)
   exec { "Build DSpace installer in ${src_dir}":
     command   => "mvn package ${mvn_params}",
     cwd       => "${src_dir}", # Run command from this directory
     user      => $owner,
     subscribe => File["${src_dir}/dspace/config/local.cfg"], # If local.cfg changes, rebuild
     refreshonly => true,  # Only run if local.cfg changes
     timeout   => 0, # Disable timeout. This build takes a while!
     logoutput => true,    # Send stdout to puppet log file (if any)
     notify    => Exec["Install DSpace to ${install_dir}"],  # Notify installation to run
   }

   # Install DSpace (via Ant)
   exec { "Install DSpace to ${install_dir}":
     # If DSpace installed, this is an update. Otherwise a fresh_install
     command   => "if [ -f ${install_dir}/bin/dspace ]; then ant update; else ant fresh_install; fi",
     provider  => shell,   # Run as a shell command
     cwd       => $ant_installer_path,    # Run command from this directory
     user      => $owner,
     logoutput => true,    # Send stdout to puppet log file (if any)
     refreshonly => true,  # Only run when triggered (by build)
  }
    # Default to requiring all packages be installed
    Package {
      ensure => installed,
    }

       package { 'maven':
      install_options => ['--no-install-recommends'],
      before          => Package['java'],
    }
    package { "ant":
      before => Package['java'],
    }

    # Install Git, needed for any DSpace development
    package { "git":
    }

    # Java installation directory
    $java_install_dir = "/usr/lib/jvm"

    # OpenJDK version/directory name (NOTE: $architecture is a "fact")
    $java_name = "java-${java_version}-openjdk-${architecture}"

    # Install Java, based on set $java_version
    package { "java":
      name => "openjdk-${java_version}-jdk",  # Install OpenJDK package (as Oracle JDK tends to require a more complex manual download & unzip)
    }

 ->

    # Set Java defaults to point at OpenJDK
    # NOTE: $architecture is a "fact" automatically set by Puppet's 'facter'.
    exec { "Update alternatives to OpenJDK Java ${java_version}":
      command => "update-java-alternatives --set ${java_name}",
      unless  => "test \$(readlink /etc/alternatives/java) = '${java_install_dir}/${java_name}/jre/bin/java'",
      path    => "/usr/bin:/usr/sbin:/bin",
    }

 ->

    # Create a "default-java" symlink (for easier JAVA_HOME setting). Overwrite if existing.
    exec { "Symlink OpenJDK to '${java_install_dir}/default-java'":
      cwd     => $java_install_dir,
      command => "ln -sfn ${java_name} default-java",
      unless  => "test \$(readlink default-java) = '${java_name}'",
      path    => "/usr/bin:/usr/sbin:/bin",
    }
}
