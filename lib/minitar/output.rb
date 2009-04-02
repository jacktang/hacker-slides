module Archive
  module Tar
    module Minitar

      # Wraps a Archive::Tar::Minitar::Writer with convenience methods and
      # wrapped stream management; Output only works with random access data
      # streams. See Output::new for details.
      class Output
        # With no associated block, +Output::open+ is a synonym for
        # +Output::new+. If the optional code block is given, it will be passed
        # the new _writer_ as an argument and the Output object will
        # automatically be closed when the block terminates. In this instance,
        # +Output::open+ returns the value of the block.
        def self.open(output)
          stream = Output.new(output)
          return stream unless block_given?

          begin
            res = yield stream
          ensure
            stream.close
          end

          res
        end

        # Creates a new Output object. If +output+ is a stream object that
        # responds to #read), then it will simply be wrapped. Otherwise, one will
        # be created and opened using Kernel#open. When Output#close is called,
        # the stream object wrapped will be closed.
        def initialize(output)
          if output.respond_to?(:write)
            @io = output
          else
            @io = ::File.open(output, "wb")
          end
          @tarwriter = Archive::Tar::Minitar::Writer.new(@io)
        end

        # Returns the Writer object for direct access.
        def tar
          @tarwriter
        end

        # Closes the Writer object and the wrapped data stream.
        def close
          @tarwriter.close
          @io.close
        end
      end

      class << self
        # Tests if +path+ refers to a directory. Fixes an apparently
        # corrupted <tt>stat()</tt> call on Windows.
        def dir?(path)
          File.directory?((path[-1] == '/') ? path : "#{path}/")
        end

        # A convenience method for wrapping Archive::Tar::Minitar::Input.open
        # (mode +r+) and Archive::Tar::Minitar::Output.open (mode +w+). No other
        # modes are currently supported.
        def open(dest, mode = "r", &block)
          case mode
          when "r"
            Input.open(dest, &block)
          when "w"
            Output.open(dest, &block)
          else
            raise "Unknown open mode for Archive::Tar::Minitar.open."
          end
        end

        # A convenience method to packs the file provided. +entry+ may either be
        # a filename (in which case various values for the file (see below) will
        # be obtained from <tt>File#stat(entry)</tt> or a Hash with the fields:
        #
        # <tt>:name</tt>::  The filename to be packed into the tarchive.
        #                   *REQUIRED*.
        # <tt>:mode</tt>::  The mode to be applied.
        # <tt>:uid</tt>::   The user owner of the file. (Ignored on Windows.)
        # <tt>:gid</tt>::   The group owner of the file. (Ignored on Windows.)
        # <tt>:mtime</tt>:: The modification Time of the file.
        #
        # During packing, if a block is provided, #pack_file yields an +action+
        # Symol, the full name of the file being packed, and a Hash of
        # statistical information, just as with
        # Archive::Tar::Minitar::Input#extract_entry.
        #
        # The +action+ will be one of:
        # <tt>:dir</tt>::           The +entry+ is a directory.
        # <tt>:file_start</tt>::    The +entry+ is a file; the extract of the
        #                           file is just beginning.
        # <tt>:file_progress</tt>:: Yielded every 4096 bytes during the extract
        #                           of the +entry+.
        # <tt>:file_done</tt>::     Yielded when the +entry+ is completed.
        #
        # The +stats+ hash contains the following keys:
        # <tt>:current</tt>:: The current total number of bytes read in the
        #                     +entry+.
        # <tt>:currinc</tt>:: The current number of bytes read in this read
        #                     cycle.
        # <tt>:name</tt>::    The filename to be packed into the tarchive.
        #                     *REQUIRED*.
        # <tt>:mode</tt>::    The mode to be applied.
        # <tt>:uid</tt>::     The user owner of the file. (+nil+ on Windows.)
        # <tt>:gid</tt>::     The group owner of the file. (+nil+ on Windows.)
        # <tt>:mtime</tt>::   The modification Time of the file.
        def pack_file(entry, outputter) #:yields action, name, stats:
          outputter = outputter.tar if outputter.kind_of?(Archive::Tar::Minitar::Output)

          stats = {}

          if entry.kind_of?(Hash)
            name = entry[:name]

            entry.each { |kk, vv| stats[kk] = vv unless vv.nil? }
          else
            name = entry
          end
          
          name = name.sub(%r{\./}, '')
          stat = File.stat(name)
          stats[:mode]   ||= stat.mode
          stats[:mtime]  ||= stat.mtime
          stats[:size]   = stat.size

          if RUBY_PLATFORM =~ /win32/
            stats[:uid]  = nil
            stats[:gid]  = nil
          else
            stats[:uid]  ||= stat.uid
            stats[:gid]  ||= stat.gid
          end

          case
          when File.file?(name)
            outputter.add_file_simple(name, stats) do |os|
              stats[:current] = 0
              yield :file_start, name, stats if block_given?
              File.open(name, "rb") do |ff|
                until ff.eof?
                  stats[:currinc] = os.write(ff.read(4096))
                  stats[:current] += stats[:currinc]
                  yield :file_progress, name, stats if block_given?
                end
              end
              yield :file_done, name, stats if block_given?
            end
          when dir?(name)
            yield :dir, name, stats if block_given?
            outputter.mkdir(name, stats)
          else
            raise "Don't yet know how to pack this type of file."
          end
        end

        # A convenience method to pack files specified by +src+ into +dest+. If
        # +src+ is an Array, then each file detailed therein will be packed into
        # the resulting Archive::Tar::Minitar::Output stream; if +recurse_dirs+
        # is true, then directories will be recursed.
        #
        # If +src+ is an Array, it will be treated as the argument to Find.find;
        # all files matching will be packed.
        def pack(src, dest, recurse_dirs = true, &block)
          Output.open(dest) do |outp|
            if src.kind_of?(Array)
              src.each do |entry|
                pack_file(entry, outp, &block)
                if dir?(entry) and recurse_dirs
                  Dir["#{entry}/**/**"].each do |ee|
                    pack_file(ee, outp, &block)
                  end
                end
              end
            else
              Find.find(src) do |entry|
                pack_file(entry, outp, &block)
              end
            end
          end
        end

        # A convenience method to unpack files from +src+ into the directory
        # specified by +dest+. Only those files named explicitly in +files+
        # will be extracted.
        def unpack(src, dest, files = [], &block)
          Input.open(src) do |inp|
            if File.exist?(dest) and (not dir?(dest))
              raise "Can't unpack to a non-directory."
            elsif not File.exist?(dest)
              FileUtils.mkdir_p(dest)
            end

            inp.each do |entry|
              if files.empty? or files.include?(entry.full_name)
                inp.extract_entry(dest, entry, &block)
              end
            end
          end
        end
      end
    end
  end
