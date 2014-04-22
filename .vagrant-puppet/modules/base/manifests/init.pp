class base {
    include packages
    include debmon

    File {
        owner => 0,
        group => 0,
        mode  => 0644,
    }

    user { 'vagrant':
        ensure => present,
        #groups => ['nagios', 'icingacmd'],
    }

    file { '/etc/motd':
        content => "Welcome to the LConf demo system.\n\n${::lsbdistdescription}\n\n",
    }
}
