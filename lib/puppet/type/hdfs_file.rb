Puppet::Type.newtype(:hdfs_file) do

  desc <<-EOT
    Ensures that a file exists in hdfs.

    Example:

        hdfs_file { '/user/hive/warehouse':
          ensure => 'directory',
          mode   => 755,
          owner  => 'hdfs',
          group  => 'hadoop',
        }
        hdfs_file { '/user/hive/db.pw':
          content => template('db.pw.erb'),
          ...
        }
        hdfs_file { '/tmp/myfile.txt':
          source => 'puppet:///cdh/hadoop/myfile.txt',
          ...
        }
        hdfs_file { '/user/hive/hive-site.xml':
          # Instead of rendering a template or pulling a file from
          # the local file repo, you can also copy a file from
          # a path on the agent machine into an hdfs path.
          local_source => '/etc/hive/conf/hive-site.xml'
        }
  EOT


  ensurable do
    newvalue(:directory) do
      provider.create
    end

    defaultto :present
  end

  newparam(:path, :namevar => true) do
    desc 'The path to the file in hdfs.'
  end

  newproperty(:owner) do
    desc 'The user to whom the file should belong.  This user must exist on the NameNode.'
    validate do |value|
      unless value =~ /^\w+/
        raise ArgumentError, "%s is not a valid user name" % value
      end
    end
  end


  newproperty(:group) do
    desc 'The group to whom the file should belong.  This group must exist on the NameNode.'
    validate do |value|
      unless value =~ /^\w+/
        raise ArgumentError, "%s is not a valid group name" % value
      end
    end
  end

  newproperty(:mode) do
    desc 'The mode the file should have as an octal string.'
  end

  # newproperty(:source) do
  #   desc 'Puppet file repo path to put in hdfs'
  # end

  newproperty(:content) do
    desc 'String content a file in hdfs should have.'
    #
    # def should=(value) do
    #   @resource.newattr(:checksum)
    #
    # end
  end
  #
  # newproperty(:local_source) do
  #   desc 'Path to file on agent node that should be copied into hdfs.  This file does not need to be managed by puppet.'
  # end



end
