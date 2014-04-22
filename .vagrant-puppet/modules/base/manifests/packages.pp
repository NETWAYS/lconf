class base::packages {

    $packages = [
        'git',
        'vim',
    ]

    package { $packages:
        ensure => present,
    }

}
