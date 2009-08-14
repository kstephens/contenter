begin
  require 'pp'

  VC_OPTS = { } unless defined? VC_OPTS

  USER = ENV['USER'] || `id -un`.chomp
  HOSTNAME = `hostname`.chomp
  

  def p4_set
    h = { }
    `p4 set`.split("\n").each{ | x | k, v = x.split('=', 2); h[k.downcase.to_sym] = v.sub(/ \([^\)]+\)$/, '') }
    h
  end


  def p4_pending_cl(opts = nil)
    opts[:p4_set] ||= p4_set
    user = opts[:user] ||= opts[:p4_set][:p4user] || USER
    hostname = opts[:hostname] ||= HOSTNAME
    name = opts[:name] ||= VC_NAME
    vc = opts[:vc] or raise 'vc not specified'
    opts[:p4client] ||= opts[:p4_set][:p4client]

    cmd = "p4 changelists -u '#{user}' -s pending -c '#{opts[:p4client]}'"
    # pp opts, cmd

    `#{cmd}`.
      split("\n").
      map do | l |
      l =~ /Change (\d+).* '.*#{name}: from #{vc}/
        $1
    end.
      compact.
      first
  end


  def p4_create_cl(opts = nil)
    name = opts[:name] ||= VC_NAME
    vc = opts[:vc] or raise 'vc not specified'

    File.open(tmp_file = "/tmp/#{$$}", "w+") do | fh |
      fh.puts <<"EOF"
Change:	new

Status:	pending

Description:
	#{name}: from #{vc}
        #{opts[:vc_m]}
Files:

EOF
    end
    out = `p4 change -i < #{tmp_file.inspect}`.chomp
    out =~ /Change (\d+) created./ ? $1 : raise("p4 change failed")
  ensure
    File.unlink(tmp_file)
  end


  desc "Displays the current P4 pending CL"
  task :p4_pending_cl do
    puts p4_pending_cl(VC_OPTS.dup)
  end

  desc "Creates or displays the P4 pending CL"
  task :p4_create_cl do
    cl = p4_pending_cl(VC_OPTS.dup) || (p4_create_cl(VC_OPTS.dup) && p4_pending_cl(VC_OPTS.dup))
    puts cl
  end
   
  desc "Displays the current VC root"
  task :vc_root do 
    puts vc_root(VC_OPTS.dup)
  end

  def vc_root(opts = nil)
    opts[:vc_root] ||= opts[:get_vc_root].call(opts)
  end


  desc "Displays the current VC change id"
  task :vc_id do 
    puts vc_id(VC_OPTS.dup)
  end

  def vc_id(opts = nil)
    opts[:vc_id] ||= opts[:get_vc_id].call(opts)
  end


  desc "Display the list of files under p4"
  task :p4_files do
    pp p4_files(VC_OPTS.dup)
  end

  def p4_files(opts)
    p4_root = `p4 files Rakefile`.chomp.sub(%r{/Rakefile#.*$}, '')
    # pp p4_root
    opts[:p4_files] ||=
      `p4 files ...`.
      gsub(%r{^.*#\d+ - delete .*$}, '').    # ignore deleted files
      gsub(/#.*$/, '').                      # remove trailing version
      gsub(%r{^#{p4_root}/}, '').            # remove p4_root prefix
      split(/\n+/).                          # split and remove blank lines
      sort
  end

  desc "Display files that should be deleted from p4 based on Manifest"
  task :p4_files_to_delete do
    puts p4_files_to_delete(VC_OPTS.dup) * "\n"
  end

  def p4_files_to_delete opts
    manifest = File.read(opts[:manifest]).split("\n").sort.uniq
    opts[:p4_files_to_delete] ||= 
      p4_files(opts).
      reject { | f | manifest.include?(f) }.
      reject { | f | VC_OPTS[:precious] && VC_OPTS[:precious] === f }.
      reject { | f | f[0 .. 0] == '.' }
  end


  desc "submit changes to and from p4 and VC"
  task :p4_submit do
    p4_submit(VC_OPTS.dup)
  end


  def p4_submit(opts = { })
    opts[:user] ||= USER
    opts[:hostname] ||= HOSTNAME
    opts[:vc_m] ||= ENV['m'] || "From #{opts[:user]}@#{opts[:hostname]}"
    opts[:p4_m] ||= "#{opts[:name]}: from #{opts[:vc]} #{opts[:vc_id]} of #{opts[:vc_root]}"
    opts[:p4_cl] ||= ENV['c'] || p4_pending_cl(opts) || (p4_create_cl(opts) && p4_pending_cl(opts))
    opts[:vc_root] ||= opts[:get_vc_root].call(opts)
    opts[:manifest] ||= 'Manifest'

    # Open everything for edit.
    sh "p4 edit ..."

    # Get latest Manifest.
    # e.g.: sh "svn update"
    opts[:update].call(opts)
 
    # Delete any files not in Manifest.
    ftd = p4_files_to_delete(opts)
    unless ftd.empty?
      sh "p4 revert #{ftd * ' '} || true"
      sh "p4 delete #{ftd * ' '}"
    end

    # Add any new files in Manifest.
    sh "p4 -x #{opts[:manifest]} add"

    # Submit any pending changes.
    # e.g: sh "svn ci -m #{vc_m.inspect}"
    opts[:submit].call(opts)

    # Get the current dst rev.
    # e.g.: `svn update`.chomp
    vc_id(opts)

    # Revert any unchanged files.
    sh "p4 revert -a ..."

    # Move everything to the changelist.
    sh "p4 reopen -c #{opts[:p4_cl]} ..."
    
    # Show change list.
    sh "p4 change -o #{opts[:p4_cl]}"

    puts "If ok run: p4 submit -c #{opts[:p4_cl]}"
    return 

    # Submit everything under here.
    sh "p4 submit -r -d #{opts[:p4_m].inspect} ..."

    # Edit everything under here.
    sh "p4 edit ..."
    
    # Reopen in the original changelist.
    if opts[:p4_cl]
      sh "p4 reopen -c #{opts[:p4_cl]} ..."
    end
  end


  def p4_edit_vc_commit(opts = nil)
    opts = opts.dup
    opts[:user] ||= USER
    opts[:hostname] ||= HOSTNAME
    m = opts[:vc_m] ||= ENV['m'] || "From #{opts[:user]}@#{opts[:hostname]}"
    sh "p4 edit ..."

    # Submit:
    # sh "svn ci -m #{m.inspect}"
    opts[:submit].call(opts)

    sh "p4 revert -a ..."
  end
end


