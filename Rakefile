require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'highline/import'

spec = Gem::Specification.load(File.join(File.dirname(__FILE__), 'hacker-slides.gemspec'))

desc 'Run all specs in spec directory'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Build rdoc'
Rake::RDocTask.new(:rdoc) do |task|
  task.rdoc_dir = 'doc'
  task.title    = 'Google Book Downloader'
  task.options = %w(--title GBookDownloader --main README --line-numbers)
  task.rdoc_files.include(['lib/**/*.rb'])
  task.rdoc_files.include(['README.textile', 'LICENSE'])
end

desc 'Generate all bundles from bundles-src'
task 'gen-bundles' do
  tar_command = 'tar'
  directory bundles_dir
  
  Dir.glob(File.join(bundles_src_dir, '*')).each do |bundle_src_path|
    bundle_name = File.basename(bundle_src_path, '.*')
    bundle_src_dir = File.join(bundles_src_dir, bundle_name)
    dest_bundle = File.join(bundles_dir, bundle_file(bundle_name))

    chdir(bundle_src_dir) do
      sh %{#{tar_command} czf #{dest_bundle} * >/dev/null 2>&1}
    end
    puts "create bundle #{bundle_name.inspect}"
  end
end

desc "Generate manifest for specified bundle"
task 'gen-manifest' do
  bundle_name = ENV['BUNDLE']
  if(bundle_name.nil?)
    puts "please specify the name of bundle"
  end

  bundle_src = File.join(bundles_src_dir, bundle_name)

  if(File.exist?(bundle_src))
    manifest = File.join(bundle_src, 'MANIFEST')
    if(!File.exist?(manifest) || 
        (File.exist?(manifest)) && (ENV['OVERWRITE'].to_s.downcase == 'true' ||
           agree("This task will overwrite the MANIFEST file. Are you sure you want to continue? [yn] ")))

      manifest_items = []
      base_len = bundle_src.size
      Dir.glob(File.join(bundle_src, '**/*')).each do |bundle_src_path|
        path = bundle_src_path[(base_len+1)..-1]
        manifest_items << path if(path != "MANIFEST")
      end
      
      File.open(manifest, 'w') do |f|
        f.puts(manifest_items.join("\n"))
      end
      puts "MANIFEST under #{bundle_name} is generated"
    end
  else
    puts "#{bundle_name} doesn't exist under bundles-src"
  end
end

def bundle_file(bundle_name)
  "#{bundle_name}.bundle"
end

def bundles_dir
  return File.expand_path(File.dirname(__FILE__) + '/bundles')
end

def bundles_src_dir
  return File.expand_path(File.dirname(__FILE__) + '/bundles-src')
end


desc "If you're building from sources, run this task first to setup the necessary dependencies"
task 'setup' do
  windows = Config::CONFIG['host_os'] =~ /windows|cygwin|bccwin|cygwin|djgpp|mingw|mswin|wince/i
  rb_bin = File.expand_path(Config::CONFIG['ruby_install_name'], Config::CONFIG['bindir'])
  spec.dependencies.select { |dep| Gem::SourceIndex.from_installed_gems.search(dep).empty? }.each do |missing|
    dep = Gem::Dependency.new(missing.name, missing.version_requirements)
    spec = Gem::SourceInfoCache.search(dep, true, true).last
    fail "#{dep} not found in local or remote repository!" unless spec
    puts "Installing #{spec.full_name} ..."
    args = [rb_bin, '-S', 'gem', 'install', spec.name, '-v', spec.version.to_s]
    args.unshift('sudo') unless windows || ENV['GEM_HOME']
    sh args.map{ |a| a.inspect }.join(' ')
  end
end

gem = Rake::GemPackageTask.new(spec) do |pkg|
  #Rake::Task['gen-bundles'].execute
  pkg.need_tar = true
  pkg.need_zip = true
end



desc "Install the package locally"
task 'install'=>['setup','package'] do |task|
  rb_bin = File.expand_path(Config::CONFIG['ruby_install_name'], Config::CONFIG['bindir'])
  args = [rb_bin, '-S', 'gem', 'install', "pkg/#{spec.name}-#{spec.version}.gem"]
  windows = Config::CONFIG['host_os'] =~ /windows|cygwin|bccwin|cygwin|djgpp|mingw|mswin|wince/i
  args.unshift('sudo') unless windows || ENV['GEM_HOME']
  cmd = args.map{|a| a.inspect}.join(' ')
  sh cmd
end
 
desc "Uninstall previously installed packaged"
task 'uninstall' do |task|
  rb_bin = File.expand_path(Config::CONFIG['ruby_install_name'], Config::CONFIG['bindir'])
  args = [rb_bin, '-S', 'gem', 'install', spec.name, '-v', spec.version.to_s]
  windows = Config::CONFIG['host_os'] =~ /windows|cygwin|bccwin|cygwin|djgpp|mingw|mswin|wince/i
  args.unshift('sudo') unless windows || ENV['GEM_HOME']
  sh args.map{ |a| a.inspect }.join(' ')
end
