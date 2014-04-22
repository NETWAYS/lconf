class lconf_demo::apache {

    package { 'apache2':
        ensure => present,
    }

    file { 'apache-redirect':
        path    => '/etc/apache2/conf.d/redirect.conf',
        content => 'RedirectMatch ^/$ /icinga',
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    service { 'apache2':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['apache2'],
    }
}
