class java {

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
}S
