class lconf_demo::packages {

    $packages = [
        'git',
        'vim',
    ]

    package { $packages:
        ensure => present,
    }

}
