class debmon{
    include apt

    apt::source { 'debmon':
        location   => 'http://debmon.org/debmon/',
        release    => "debmon-${::lsbdistcodename}",
        repos      => 'main',
        key        => '29D662D2',
        key_source => 'http://debmon.org/debmon/repo.key',
    }

}
