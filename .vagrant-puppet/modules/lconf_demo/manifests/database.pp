class lconf_demo::database {
    require mysql::client
    require mysql::server

    mysql_user { 'vagrant@localhost':
        ensure => present,
    }
    mysql_grant { 'vagrant@localhost/*.*':
        ensure     => present,
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => '*.*',
        user       => 'vagrant@localhost',
    }
}
