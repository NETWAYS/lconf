class icinga {

    package { 'icinga':
        ensure => latest,
    }

    service { 'icinga':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['icinga'],
    }

    file { 'icinga-cgi-htpasswd':
        ensure  => file,
        path    => '/etc/icinga/htpasswd.users',
        owner   => 'root',
        group   => 'www-data',
        mode    => '0640',
        require => Package['icinga'],
    }

    augeas { 'icinga-cgi-admin':
        lens    => 'Htpasswd.lns',
        incl    => '/etc/icinga/htpasswd.users',
        changes => [
            # hashed: vagrant
            'set icingaadmin $apr1$sEuopTZU$pSsO9XsF7WR7RaqnXBtLY0',
        ],
        require => File['icinga-cgi-htpasswd'],
    }

    augeas { 'icinga-disable-notifications':
        lens    => 'NagiosCfg.lns',
        incl    => '/etc/icinga/icinga.cfg',
        changes => [
            'set enable_notifications 0',
        ],
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    augeas { 'icinga-enable-commandpipe':
        lens    => 'NagiosCfg.lns',
        incl    => '/etc/icinga/icinga.cfg',
        changes => [
            'set check_external_commands 1',
        ],
        require => Package['icinga'],
        notify  => Exec['icinga-reconfigure'],
    }

    exec { 'icinga-reconfigure':
        command     => 'dpkg-reconfigure icinga-common',
        path        => $::path,
        environment => [
            'DEBIAN_FRONTEND=noninteractive',
        ],
        refreshonly => true,
        notify      => Service['icinga'],
    }

}
