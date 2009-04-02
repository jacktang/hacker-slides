module Archive
  module Tar
    module Minitar

      # The class that writes a tar format archive to a data stream.
      class Writer
        # A stream wrapper that can only be written to. Any attempt to read
        # from this restricted stream will result in a NameError being thrown.
        class RestrictedStream
          def initialize(anIO)
            @io = anIO
          end

          def write(data)
            @io.write(data)
          end
        end

        # A RestrictedStream that also has a size limit.
        class BoundedStream < Archive::Tar::Minitar::Writer::RestrictedStream
          # The exception raised when the user attempts to write more data to
          # a BoundedStream than has been allocated.
          class FileOverflow < RuntimeError; end

          # The maximum number of bytes that may be written to this data
          # stream.
          attr_reader :limit
          # The current total number of bytes written to this data stream.
          attr_reader :written

          def initialize(io, limit)
            @io       = io
            @limit    = limit
            @written  = 0
          end

          def write(data)
            raise FileOverflow if (data.size + @written) > @limit
            @io.write(data)
            @written += data.size
            data.size
          end
        end

        # With no associated block, +Writer::open+ is a synonym for
        # +Writer::new+. If the optional code block is given, it will be
        # passed the new _writer_ as an argument and the Writer object will
        # automatically be closed when the block terminates. In this instance,
        # +Writer::open+ returns the value of the block.
        def self.open(anIO)
          writer = Writer.new(anIO)

          return writer unless block_given?

          begin
            res = yield writer
          ensure
            writer.close
          end

          res
        end

        # Creates and returns a new Writer object.
        def initialize(anIO)
          @io     = anIO
          @closed = false
        end

        # Adds a file to the archive as +name+. +opts+ must contain the
        # following values:
        #
        # <tt>:mode</tt>::  The Unix file permissions mode value.
        # <tt>:size</tt>::  The size, in bytes.
        #
        # +opts+ may contain the following values:
        #
        # <tt>:uid</tt>:    The Unix file owner user ID number.
        # <tt>:gid</tt>:    The Unix file owner group ID number.
        # <tt>:mtime</tt>:: The *integer* modification time value.
        #
        # It will not be possible to add more than <tt>opts[:size]</tt> bytes
        # to the file.
        def add_file_simple(name, opts = {}) # :yields BoundedStream:
          raise Archive::Tar::Minitar::BlockRequired unless block_given?
          raise Archive::Tar::ClosedStream if @closed

          name, prefix = split_name(name)

          header = { :name => name, :mode => opts[:mode], :mtime => opts[:mtime],
            :size => opts[:size], :gid => opts[:gid], :uid => opts[:uid],
            :prefix => prefix }
          header = Archive::Tar::PosixHeader.new(header).to_s 
          @io.write(header)

          os = BoundedStream.new(@io, opts[:size])
          yield os
          # FIXME: what if an exception is raised in the block?

          min_padding = opts[:size] - os.written
          @io.write("\0" * min_padding)
          remainder = (512 - (opts[:size] % 512)) % 512
          @io.write("\0" * remainder)
        end

        # Adds a file to the archive as +name+. +opts+ must contain the
        # following value:
        #
        # <tt>:mode</tt>::  The Unix file permissions mode value.
        #
        # +opts+ may contain the following values:
        #
        # <tt>:uid</tt>:    The Unix file owner user ID number.
        # <tt>:gid</tt>:    The Unix file owner group ID number.
        # <tt>:mtime</tt>:: The *integer* modification time value.
        #
        # The file's size will be determined from the amount of data written
        # to the stream.
        #
        # For #add_file to be used, the Archive::Tar::Minitar::Writer must be
        # wrapping a stream object that is seekable (e.g., it responds to
        # #pos=). Otherwise, #add_file_simple must be used.
        #
        # +opts+ may be modified during the writing to the stream.
        def add_file(name, opts = {}) # :yields RestrictedStream, +opts+:
          raise Archive::Tar::Minitar::BlockRequired unless block_given?
          raise Archive::Tar::Minitar::ClosedStream if @closed
          raise Archive::Tar::Minitar::NonSeekableStream unless @io.respond_to?(:pos=)

          name, prefix = split_name(name)
          init_pos = @io.pos
          @io.write("\0" * 512) # placeholder for the header

          yield RestrictedStream.new(@io), opts
          # FIXME: what if an exception is raised in the block?

          size      = @io.pos - (init_pos + 512)
          remainder = (512 - (size % 512)) % 512
          @io.write("\0" * remainder)

          final_pos = @io.pos
          @io.pos   = init_pos

          header = { :name => name, :mode => opts[:mode], :mtime => opts[:mtime],
            :size => size, :gid => opts[:gid], :uid => opts[:uid],
            :prefix => prefix }
          header = Archive::Tar::PosixHeader.new(header).to_s
          @io.write(header)
          @io.pos = final_pos
        end

        # Creates a directory in the tar.
        def mkdir(name, opts = {})
          raise ClosedStream if @closed
          name, prefix = split_name(name)
          header = { :name => name, :mode => opts[:mode], :typeflag => "5",
            :size => 0, :gid => opts[:gid], :uid => opts[:uid],
            :mtime => opts[:mtime], :prefix => prefix }
          header = Archive::Tar::PosixHeader.new(header).to_s
          @io.write(header)
          nil
        end

        # Passes the #flush method to the wrapped stream, used for buffered
        # streams.
        def flush
          raise ClosedStream if @closed
          @io.flush if @io.respond_to?(:flush)
        end

        # Closes the Writer.
        def close
          return if @closed
          @io.write("\0" * 1024)
          @closed = true
        end

        private
        def split_name(name)
          raise FileNameTooLong if name.size > 256
          if name.size <= 100
            prefix = ""
          else
            parts = name.split(/\//)
            newname = parts.pop

            nxt = ""

            loop do
              nxt = parts.pop
              break if newname.size + 1 + nxt.size > 100
              newname = "#{nxt}/#{newname}"
            end

            prefix = (parts + [nxt]).join("/")

            name = newname

            raise FileNameTooLong if name.size > 100 || prefix.size > 155
          end
          return name, prefix
        end
      end
    end
  end
end
