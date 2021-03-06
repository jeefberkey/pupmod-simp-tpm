Puppet::Type.type(:tpm2_ownership).provide(:tpm2tools) do
  desc 'The tpm2tools providers uses the TCG software stack (tpm2-tss) and commands provided
    by tpm2-tools rpm to set the passwords for a TPM 2.0. The current tools
    can not check if the password is set so it will set it and set a flag.  In later versions
    of the tools you can check the status and it the password is unset, you can set it.

    @author SIMP Team https://simp-project.com'

  has_feature :take_ownership

  confine :has_tpm => true
  confine :tpm_version => 'tpm2'

  defaultfor :kernel => :Linux

  commands :tpm2_takeownership => 'tpm2_takeownership'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  # Dump the owner password to a flat file
  #
  # @param [String] path where fact will be dumped
  def dump_pass(name, vardir)
    require 'json'

    pass_file = File.expand_path("#{vardir}/simp/#{name}/#{name}data.json")

    passwords = { "owner_auth"   => resource[:owner_auth],
                  "lock_auth"    => resource[:lock_auth],
                  "endorse_auth" => resource[:endorse_auth]
                }
    # Check to make sure the SIMP directory in vardir exists, or create it
    if !File.directory?( File.dirname(pass_file) )
      FileUtils.mkdir_p( File.dirname(pass_file), :mode => 0750 )
      FileUtils.chown( 'root','root', File.dirname(pass_file) )
      FileUtils.chmod 0700, File.dirname(pass_file)
    end

    # Dump the password to pass_file
    file = File.new( pass_file, 'w', 0600 )
    file.write( passwords.to_json )
    file.close

  end

  # Call  tpm2_takeownership, create the owned file,  and write out the data file if needed.
  # vardir is used for test purposes only bec
  # @return nil if success, the error if there was one
  def takeownership(name)
    require 'json'
    require 'fileutils'

    # options = gen_tcti_args() + gen_passwd_args()
    options = gen_passwd_args()

    begin
      tpm2_takeownership(options)

      ownerdir = "#{Puppet[:vardir]}/simp/#{name}"
      FileUtils.mkdir_p("#{ownerdir}", :mode => 0700) unless Dir.exists?("#{ownerdir}")
      FileUtils.chown( 'root','root', "#{ownerdir}" )

      file = File.new("#{ownerdir}/owned", "w")
      file.write("#{name}")
      file.close

      if resource[:local]
        dump_pass(name, Puppet[:vardir])
      end
    rescue Puppet::ExecutionFailure => e
      warn("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end

    return nil
  end


  # Generate standard args for connecting to the TPM.  These arguements
  # are common for most TPM2 commands.
  #
  # @return [String] Return a string of the tcti arguements.
  # The tcti options are part of the tpm2_tools version 2 and later.
  # I commented out the call so they would not be used yet.
  def gen_tcti_args()
    options = []

    debug('tpm2_takeownership setting tcti args.')
    case resource[:tcti]
    when :devicefile
      options << ["--tcti device","-d", "#{resource[:devicefile]}"]
    else
      options << ["--tcti socket", "-R", "#{resource[:socket_address]}", "-p", "#{resource[:socket_port]}"]
    end

    options
  end

  # Generate the passwords arguments.
  #
  # @return [String] Return a string arguements.
  def gen_passwd_args()
    options = []

    debug('tpm2_takeownership setting passwd args.')
    # where to check that at least one of these is set?  Here or in type.
    if resource[:owner_auth].length > 0
      options << ["-o", "#{resource[:owner_auth]}"]
    end
    if resource[:lock_auth].length > 0
      options << ["-l","#{resource[:lock_auth]}"]
    end
    if resource[:endorse_auth].length > 0
      options << ["-e", "#{resource[:endorse_auth]}"]
    end

    unless options.any?
      fail("At least one of owner_auth, lock_auth or endorse_auth must be provided")
    else
      if resource[:in_hex]
        options << "-X"
      end
    end

    options
  end

  # Check and see if the data file exists for the tpm.  In version 2 you can
  # use tpm2_dump_capability to check what passwords are set.
  def self.read_sys( sys_glob = '/sys/class/tpm/*')
    Dir.glob(sys_glob).collect do |tpm_path|
      debug(tpm_path)
      tpmname = File.basename(tpm_path)
      ownerfile = "#{Puppet[:vardir]}/simp/#{tpmname}/owned"
      if File.exists?(ownerfile)
        currently_owned = :true
      else
        currently_owned = :false
      end
      {
        name:  tpmname,
        owned: currently_owned
      }
    end
  end

  def self.instances
    read_sys.collect do |tpm|
      debug("tpm2: Adding tpm: #{tpm[:name]} with owned: #{tpm[:owned].to_s}")
      new(tpm)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def owned=(should)
    debug 'tpm2: Setting property_flush to should'
    @property_flush[:owned] = should
  end

  def owned
    @property_hash[:owned]
  end

  def flush
    debug 'tpm2: Flushing tpm2_ownership'
    if @property_flush[:owned] == :true  and @property_hash[:owned] == :false
      output = takeownership(@property_hash[:name])
      unless output.nil?
        fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output.inspect}"
      end
      @property_hash[:owned] = :true
    end
  end

end
