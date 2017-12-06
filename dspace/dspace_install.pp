class dspace::install {
define dspace::install ($owner             = dspace,
                        $group             = $owner,
            		$ $src_dir            = "/etc/puppetlabs/code/environments/production/modules/dspace/dspace-src",
  			$install_dir        = "/etc/puppetlabs/code/environments/production/modules/dspace/dspace",
			$installer_dir_name = 'dspace-installer',
                        $git_branch        = 'puppet',
                        $mvn_params        = '',
                        $ant_installer_dir = $dspace::installer_dir_name,
                        $admin_firstname   = 'cherin',
                        $admin_lastname    = 'onyango',
                        $admin_email       = 'cherin.onyango@digitaldividedata.com',
                        $admin_passwd      = 'dspace12',
                        $admin_language    = undef,
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

   # Create initial administrator (if specified)
   if $admin_email and $admin_passwd and $admin_firstname and $admin_lastname and $admin_language
   {
     exec { "Create DSpace Administrator":
       command   => "${install_dir}/bin/dspace create-administrator -e ${admin_email} -f ${admin_firstname} -l ${admin_lastname} -p ${admin_passwd} -c ${admin_language}",
       cwd       => $install_dir,
       user      => $owner,
       logoutput => true,
       require   => Exec["Install DSpace to ${install_dir}"],
     }
   }
}

}



