
Puppet::Type.type(:hdfs_file).provide(:hdfs) do
  include Puppet::Util::Checksums

  # ????
  # defaultfor '' => false

  # defaultfor :operatingsystem => :nonya

  # Should I use absolute path?  Or just rely on $PATH?
  commands :hdfs => 'hdfs'
  # Have to use sudo -u hdfs in order to run commands as hdfs super user
  commands :sudo => 'sudo'

  commands :checksum => 'md5sum'

  def exists?
    return false unless present?

    # Raise an error if the file exists but it not what it should be
    if @resource[:ensure] == :directory and file?
      # TODO: Puppet::Error???
      raise Puppet::Error, "Cannot ensure #{@resource[:path]} is a directory, it already exists as a file."
    end

    if @resource[:ensure] == :present and directory?
      raise Puppet::Error, "Cannot ensure #{@resource[:path]} is a file, it already exists as a directory."
    end


    # TODO: use -stat %F instead of -test?
    # Return true if the file is present and it is what it is ensured to be
    ret = (@resource[:ensure] == :directory) ? directory? : file?

    puts "dir: #{@is_directory}, file: #{@is_file}, ret: #{ret}"
    return ret
  end

  def create
    # WHYYY is create being called if exists returns true?!?!!
    # return if exists?

    puts "creating with ensure " + @resource[:ensure].to_s
    begin
      if @resource[:ensure] == :directory
        dfs(['-mkdir', @resource[:path]])
      else
        dfs(['-touchz', @resource[:path]])
      end

      unless self.owner == @resource.should(:owner)
        self.owner = @resource.should(:owner)
      end
      unless self.group == @resource.should(:group)
        self.group = @resource.should(:group)
      end
      unless self.mode == @resource.should(:mode)
        self.mode = @resource.should(:mode)
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.info("create had an execution failure: #{e.inspect}")
      fail e
    end
  end

  def destroy
    begin
      if @resource[:ensure] == :directory
        dfs(['-rm', '-r', '-f', @resource[:path]])
      else
        dfs(['-rm', '-f', @resource[:path]])
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.info("destory had an execution failure: #{e.inspect}")
      fail e
    end
  end

  def owner
    (defined? @owner) ? @owner : @owner = stat('u')
  end
  def owner=(value)
    dfs(['-chown', value, @resource[:path]])
  end


  def group
    (defined? @group) ? @group : @group = stat('g')
  end
  def group=(value)
    dfs(['-chgrp', value, @resource[:path]])
  end

  def mode
    # extract human readable permissions out of dfs -ls
    permissions = dfs(['-ls', '-d', @resource[:path]]).split(/s/)[0]
    # convert it to octal string and cache it.
    (defined? @mode) ? @mode : @mode = permissions_to_octal_string(permissions)
  end
  def mode=(value)
    dfs(['-chmod', value, @resource[:path]])
  end

  def content
    (defined? @checksum) ? @checksum : @c = stat('g')
  end
  def content=(value)
    dfs(['-chgrp', value, @resource[:path]])
  end


  # Helper methods and command methods below
  private

  def present?
    (defined? @is_present) ? @is_present : @is_present = test('e')
  end

  def file?
    (defined? @is_file) ? @is_file : @is_file = test('f')
  end

  def directory?
    (defined? @is_directory) ? @is_directory : @is_directory = test('d')
  end

  def test(testopt)
    begin
      dfs(['-test', '-' + testopt, @resource[:name]])
    rescue Puppet::ExecutionFailure => e
      Puppet.info("test had an execution failure: #{e.inspect}")
      return false
    end

    return true
  end

  def stat(statopt)
    dfs(['-stat', '%' + statopt, @resource[:name]])
  end

  def permissions_to_octal_string(permissions)
    is_sticky = permissions.include?('t')

    # remove the first character from the string.  It will be 'd' if directory, '-' otherwise.
    permissions[0] = ''

    # convert permissions to a binary looking string.
    # rwxt => 1, and anything else => 0
    permissions.gsub!(/[rwxt]/, '1').gsub!(/[^1]/, '0')

    # prepend 1 if we want world stickyness
    permissions = is_sticky ? '1'.concat(permissions) : '0'.concat(permissions)

    # convert binary looking string to number and then to an octal looking string
    return permissions.to_i(2).to_s(8)  # => # 0111101101 => '0755'
  end

  # ???
  # autorequire(:file) do
  #      self[:file]
  #  end

  def dfs(args)
    Puppet.info('dfs cmd: ' + 'sudo -u hdfs hdfs dfs ' + args.join(' '))
    sudo(['-u', 'hdfs', 'hdfs', 'dfs'] + args)
    # hdfs(['dfs'] + args)
  end


end
