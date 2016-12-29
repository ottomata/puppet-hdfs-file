hdfs_file { '/tmp/hdfs-puppet-test01':
    ensure => 'directory',
    mode   => '1775',
    owner => 'hdfs',
    group => 'hadoop',
}
