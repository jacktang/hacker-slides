require 'rubygems'
require 'zlib'
require 'open-uri'
require 'fileutils'

require 'minitar'

module HackerSlides
  class Bundle
    class << self

      # install remote/local bundle 
      def install(src, bundle)
        
        bundle = "#{bundle}.bundle" if(File.extname(bundle) != '.bundle')
        
        if(src)
          bundle_path = File.join(src, bundle)
        else
          bundle_path = File.expand_path(bundle)
        end
        dest = File.join(usr_bundle_dir, bundle)
        open(bundle_path) do |stream|
          File.open(dest, 'wb') do |f|
            f.write(stream.read)
          end
        end

      end

      def list_bundles
        builtin_bundles = []
        usr_bundles = []

        Dir.glob(File.join(usr_bundle_dir, '*')).each do |bundle|
          bundle_name = File.basename(bundle, '.*')
          usr_bundles << bundle_name 
        end

        Dir.glob(File.join(builtin_bundle_dir, '*')).each do |bundle|
          bundle_name = File.basename(bundle, '.*')
          builtin_bundles << bundle_name 
        end
        return builtin_bundles, usr_bundles
      end

      def builtin_bundle_dir
        return File.expand_path(File.dirname(__FILE__) + '/../../bundles')
      end

      def usr_bundle_dir
        bundle_dir = File.join(cache_dir, 'bundles')
        unless File.exists?(bundle_dir)
          FileUtils.mkdir(bundle_dir)
        end
        return bundle_dir
      end

      def lookup_bundle_path(bundle_name)
        bundle = File.join(usr_bundle_dir, "#{bundle_name}.bundle")
        if(File.exists?(bundle))
          return bundle
        else
          bundle = File.join(builtin_bundle_dir, "#{bundle_name}.bundle") 
          return bundle if(File.exists?(bundle))
        end
      end

      def cache_dir
        if(PLATFORM =~ /win32/)
          dir = File.join(ENV['USERPROFILE'], '.hackerslides')
        else
          dir = File.join(File.expand_path("~"), ".hackerslides")
        end

        unless File.exist?(dir)
          FileUtils.mkdir(dir)
        end
        return dir
      end
      
      def extract_files_from_bundle(bundle, files, dest)
        Zlib::GzipReader.open(bundle) do |tgz|
          Archive::Tar::Minitar.unpack(tgz, dest, files)
        end
      end

      def load_manifest(bundle)
        Zlib::GzipReader.open(bundle) do |tgz|
          Archive::Tar::Minitar::Input.open(tgz) do |stream|
            stream.each do |entry|
              if(entry.name == 'MANIFEST')
                manifest = []
                entry.read.split(/\n/).each_with_index do |line,i|
                  case line
                  when /^\s*$/
                    # skip empty lines
                  when /^\s*#.*$/
                    # skip comment lines
                  else       
                    manifest << line.strip
                  end
                end
                return manifest
              end
            end
          end
        end
        return nil
      end

    end
  end
end
