class lconf_demo {
    # subclasses
    include packages
    include database
    include augeas
    include apache

    # modules
    include debmon
    include icinga

    File {
        owner => 0,
        group => 0,
        mode  => 0644,
    }

    user { 'vagrant':
        ensure => present,
        groups => ['adm', 'sudo'],
    }

    file { '/etc/motd':
        content => "Welcome to the LConf demo system.\n\n${::lsbdistdescription}\n\n",
    }
}
