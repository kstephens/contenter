require 'rubygems'
require 'rake'

VC_NAME = 'contenter'

begin
  require 'echoe'
 
  $e = Echoe.new(VC_NAME, '1.0') do |p|
    p.rubyforge_name = 'contenter'
    p.summary = "Contenter - Enterprise Content Manager"
    p.description = "For more info:

http://contenter.org/
http://kurtstephens.com/contenter
http://github.com/kstephens/contenter/tree/master
"
    p.url = "http://git/"
    p.author = ['Kurt Stephens']
    p.email = "ruby-contenter@contenter.org"
    # p.dependencies = ["launchy"]
  end
 
rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end


task :tgz do
  sh "cd .. && tar -czvf contenter.tar.gz contenter"
end

######################################################################

require 'lib/tasks/p4_git'
VC_OPTS[:manifest] = 'Manifest'
VC_OPTS[:precious] = /^contrib\//



