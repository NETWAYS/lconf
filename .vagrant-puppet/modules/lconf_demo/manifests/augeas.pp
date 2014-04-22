class lconf_demo::augeas {
    if $::augeasversion < '1.0.0' {
        file { 'augeas_htpasswd':
            ensure => present,
            path   => '/usr/share/augeas/lenses/htpasswd.aug',
            source => 'puppet:///modules/lconf_demo/augeas/htpasswd.aug',
        }
    }
}
