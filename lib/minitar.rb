#!/usr/bin/env ruby
#--
# Archive::Tar::Minitar 0.5.2
#   Copyright 2004 Mauricio Julio Ferna'ndez Pradier and Austin Ziegler
#
# This program is based on and incorporates parts of RPA::Package from
# rpa-base (lib/rpa/package.rb and lib/rpa/util.rb) by Mauricio and has been
# adapted to be more generic by Austin.
#
# It is licensed under the GNU General Public Licence or Ruby's licence.
#
# $Id: minitar.rb 213 2008-02-26 22:32:11Z austin $
#++
require 'zlib'
require 'fileutils'
require 'find'

# = Archive::Tar::Minitar 0.5.2
# Archive::Tar::Minitar is a pure-Ruby library and command-line
# utility that provides the ability to deal with POSIX tar(1) archive
# files. The implementation is based heavily on Mauricio Ferna'ndez's
# implementation in rpa-base, but has been reorganised to promote
# reuse in other projects.
#
# This tar class performs a subset of all tar (POSIX tape archive)
# operations. We can only deal with typeflags 0, 1, 2, and 5 (see
# Archive::Tar::PosixHeader). All other typeflags will be treated as
# normal files.
#
# NOTE::: support for typeflags 1 and 2 is not yet implemented in this
#         version.
#
# This release is version 0.5.2. The library can only handle files and
# directories at this point. A future version will be expanded to
# handle symbolic links and hard links in a portable manner. The
# command line utility, minitar, can only create archives, extract
# from archives, and list archive contents.
#
# == Synopsis
# Using this library is easy. The simplest case is:
#
#   require 'zlib'
#   require 'archive/tar/minitar'
#   include Archive::Tar
#
#     # Packs everything that matches Find.find('tests')
#   File.open('test.tar', 'wb') { |tar| Minitar.pack('tests', tar) }
#     # Unpacks 'test.tar' to 'x', creating 'x' if necessary.
#   Minitar.unpack('test.tar', 'x')
#
# A gzipped tar can be written with:
#
#   tgz = Zlib::GzipWriter.new(File.open('test.tgz', 'wb'))
#     # Warning: tgz will be closed!
#   Minitar.pack('tests', tgz)
#
#   tgz = Zlib::GzipReader.new(File.open('test.tgz', 'rb'))
#     # Warning: tgz will be closed!
#   Minitar.unpack(tgz, 'x')
#
# As the case above shows, one need not write to a file. However, it
# will sometimes require that one dive a little deeper into the API,
# as in the case of StringIO objects. Note that I'm not providing a
# block with Minitar::Output, as Minitar::Output#close automatically
# closes both the Output object and the wrapped data stream object.
#
#   begin
#     sgz = Zlib::GzipWriter.new(StringIO.new(""))
#     tar = Output.new(sgz)
#     Find.find('tests') do |entry|
#       Minitar.pack_file(entry, tar)
#     end
#   ensure
#       # Closes both tar and sgz.
#     tar.close
#   end
#
# == Copyright
# Copyright 2004 Mauricio Julio Ferna'ndez Pradier and Austin Ziegler
#
# This program is based on and incorporates parts of RPA::Package from
# rpa-base (lib/rpa/package.rb and lib/rpa/util.rb) by Mauricio and
# has been adapted to be more generic by Austin.
#
# 'minitar' contains an adaptation of Ruby/ProgressBar by Satoru
# Takabayashi <satoru@namazu.org>, copyright 2001 - 2004.
#
# This program is free software. It may be redistributed and/or
# modified under the terms of the GPL version 2 (or later) or Ruby's
# licence.
module Archive
  module Tar
    module Minitar

      VERSION = "0.5.2"

      # The exception raised when a wrapped data stream class is expected to
      # respond to #rewind or #pos but does not.
      class NonSeekableStream < StandardError; end
      # The exception raised when a block is required for proper operation of
      # the method.
      class BlockRequired < ArgumentError; end
      # The exception raised when operations are performed on a stream that has
      # previously been closed.
      class ClosedStream < StandardError; end
      # The exception raised when a filename exceeds 256 bytes in length,
      # the maximum supported by the standard Tar format.
      class FileNameTooLong < StandardError; end
      # The exception raised when a data stream ends before the amount of data
      # expected in the archive's PosixHeader.
      class UnexpectedEOF < StandardError; end

    end

  end
end

require 'minitar/posix_header'
require 'minitar/writer'
require 'minitar/reader'
require 'minitar/input'
require 'minitar/output'


