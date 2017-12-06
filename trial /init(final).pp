class ntp {

    include ntp::install
    include ntp::config
    include ntp::service
}

#add all the subclasses into once main class
