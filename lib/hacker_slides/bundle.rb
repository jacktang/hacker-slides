require 'rubygems'
require 'zlib'
require 'minitar'

module HackerSlides
  class Bundle
    class << self

      def list_bundles
        builtin_bundles = []
        usr_bundles = []
        Dir.glob(File.join(builtin_bundle_dir, '*')).each do |bundle|
          bundle_name = File.basename(bundle, '.*')
          builtin_bundles << bundle_name 
        end
        return builtin_bundles, usr_bundles
      end

      def builtin_bundle_dir
        return File.expand_path(File.dirname(__FILE__) + '/../../bundles')
      end

      def lookup_bundle_path(bundle_name)
        return File.join(builtin_bundle_dir, "#{bundle_name}.bundle")
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
