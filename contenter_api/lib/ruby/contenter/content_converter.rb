require 'contenter'

require 'pathname'
require 'tempfile'
require 'open3'
require 'digest/md5'

require 'contenter/hash' # Hash#project

module Contenter
  class ContentConverter
    BIN_PREFIX = ''.freeze

    class Error < ::Exception
      class Command < self; end
      class NoConversion < self; end
    end

    attr_accessor :src, :dst

    attr_accessor :verbose

    def initialize opts = nil
      @verbose = false
      opts ||= EMPTY_HASH
      opts.each do | k, v |
        send("#{k}=", v)
      end
      @src = Content.coerce @src
      @dst = Content.coerce @dst
    end

    def convert!
      convert_src_dst! src, dst
    end

    def convert_src_dst! src, dst
      dst.mime_type = nil if dst.mime_type == ''
      dst.mime_type ||= src.mime_type
      if src.mime_type == dst.mime_type && (! dst.options || dst.options.empty?)
        FileUtils.copy(src.file.to_s, dst.file_or_tmp.to_s)
      else
        case
        when src.mime_type =~ /\Atext\//  && dst.mime_type =~ /\Atext\//
          convert_text_to_text! src, dst
        when src.mime_type =~ /\Aimage\// && dst.mime_type =~ /\Aimage\//
          convert_image_to_image! src, dst
        else
          raise Error::NoConversion, "src.mime_type = #{src.mime_type.inspect}, dst.mime_type = #{dst.mime_type.inspect}"
        end
      end

      # Force loading of tmp data before tmpfiles are deleted.
      dst.data

      self
    ensure 
      src.delete_tmpfiles!
      dst.delete_tmpfiles!
    end


    ###################################################################
    # text => text
    #

    def convert_text_to_text! src, dst
      result = convert_text_to_text_cmds src, dst

      if result[:cmds].empty?
        dst.file = src.file
        dst.data = src.data
      else
        result[:cmds].each do | cmd |
          $stderr.puts " => #{cmd}" if @verbose
          system(cmd) || (raise Error::Command, "#{cmd}: #{$?.inspect}")
        end

        dst.file = result[:dst_file]
      end

      dst.data # force loading of the data.
      dst._delegate ||= src._delegate # pass-through

      self
    end


    def convert_text_to_text_cmds src, dst, result = nil
      result ||= { }
      result[:src] = src
      result[:dst] = dst
      cmds = result[:cmds] ||= [ ]

      case
      when src.mime_type.to_s == 'text/html' && dst.mime_type.to_s == 'text/plain'
        dst = dst.file_or_tmp(nil, :plain).to_s
        cmds << "#{BIN_PREFIX}lynx --force-html --dump #{src.force_to_file.to_s.inspect} > #{dst.inspect}"
        result[:dst_file] = dst
      when src.mime_type.to_s == 'text/plain' && dst.mime_type.to_s == 'text/html'
        raise Error::NoConversion, "src.mime_type = #{src.mime_type.inspect}, dst.mime_type = #{dst.mime_type.inspect}"
      else
        raise Error::NoConversion, "src.mime_type = #{src.mime_type.inspect}, dst.mime_type = #{dst.mime_type.inspect}"
      end

      result 
    end


    ###################################################################
    # image => image
    #


    def convert_image_to_image! src, dst
      result = convert_image_to_image_cmds src, dst

      result[:cmds].each do | cmd |
        $stderr.puts " => #{cmd}" if @verbose
        system(cmd) || (raise Error::Command, "#{cmd}: #{$?.inspect}")
      end

      dst.file = result[:dst_file]
      dst.data # force loading of the data.
      dst._delegate ||= src._delegate # pass-through

      self
    end

    def convert_image_to_image_cmds src, dst, result = nil
      result ||= { }
      result[:src] = src
      result[:dst] = dst

      convert_image_to_pnm_cmds src, dst, result

      convert_pnm_rotate src, dst, result
      convert_pnm_size src, dst, result
 
      convert_pnm_to_image_cmds src, dst, result

      result 
    end

    def convert_image_to_pnm_cmds src, dst, result = nil
      result ||= { }

      cmds = result[:cmds] ||= [ ]

      topnm = "#{BIN_PREFIX}#{src.suffix.sub(/\A\./, '')}topnm"
      src_file = src.file_or_tmp(nil, :fill).to_s

      case src.suffix
      when '.pnm'
        result[:pnm_file] = src_file
        return result
      when '.png'
        result[:pnm_alpha_file] = src.tmpfile("alpha", ".pgm")
        cmds << "#{topnm} -alpha #{src_file.inspect} > #{result[:pnm_alpha_file].to_s.inspect}"
      when '.gif'
        result[:pnm_alpha_file] = src.tmpfile("alpha", ".pgm")
        topnm << " -alphaout=#{result[:pnm_alpha_file].to_s.inspect}"
      end

      result[:pnm_file] = src.tmpfile("pnm", ".pnm")

      topnm << " #{src.file_or_tmp(nil, :fill).to_s.inspect} > #{result[:pnm_file]}"
      cmds << topnm

      result
    end

    def convert_pnm_size src, dst, result = nil
      result ||= { }
      cmds = result[:cmds] ||= [ ]

      w = dst.options[:width]
      h = dst.options[:height]
      if w || h
        resize_file = src.tmpfile("resize", ".pnm")
        resize_alpha_file = result[:pnm_alpha_file] && src.tmpfile("resize_alpha", ".pgm")

        w ||= 0
        h ||= 0
        if w == 0 || h == 0
          w_h = w > h ? w : h
          w = h = w_h
        end

        cmd = "#{BIN_PREFIX}pnmscale -xysize #{w || 0} #{h || 0}"
        cmds << "#{cmd} #{result[:pnm_file]} > #{resize_file}"
        cmds << "#{cmd} #{result[:pnm_alpha_file]} > #{resize_alpha_file}" if resize_alpha_file

        result[:pnm_file] = resize_file
        result[:pnm_alpha_file] = resize_alpha_file
      end

      result
    end

    def convert_pnm_rotate src, dst, result = nil
      result ||= { }
      cmds = result[:cmds] ||= [ ]

      if (r = dst.options[:rotate]) && r.to_i != 0
        rotate_file = src.tmpfile("rotate", ".pnm")

        # Create an alpha map white card, if dst support alpha.
        if dst.image_supports_alpha? && ! result[:pnm_alpha_file]
          # $stderr.puts "  src = #{src.inspect}"
          rotate_alpha_file = result[:pnm_alpha_file] = src.tmpfile("rotate_alpha_card", ".pgm")
          # cmds << "#{BIN_PREFIX}pbmmake -white #{src.image_size[:width]} #{src.image_size[:height]} | #{BIN_PREFIX}pbmtopgm  1 1 > #{rotate_alpha_file.to_s.inspect}"
          cmds << "#{BIN_PREFIX}pbmmake -white #{src.image_size[:width]} #{src.image_size[:height]} > #{rotate_alpha_file.to_s.inspect}"
        end
        rotate_alpha_file = result[:pnm_alpha_file] && src.tmpfile("rotate_alpha", ".pgm")

        cmd = "#{BIN_PREFIX}pnmrotate #{r}"
        cmds << "#{cmd} #{result[:pnm_file]} > #{rotate_file}"
        cmds << "#{cmd} #{result[:pnm_alpha_file]} > #{rotate_alpha_file}" if rotate_alpha_file

        result[:pnm_file] = rotate_file
        result[:pnm_alpha_file] = rotate_alpha_file
      end

      result
    end

    def convert_pnm_to_image_cmds src, dst, result = nil
      result ||= { }
      cmds = result[:cmds] ||= [ ]

      frompnm = "#{BIN_PREFIX}pnmto#{dst.suffix.sub(/\A\./, '')}"

      case dst.suffix
      when '.pnm'
        result[:dst_file] = result[:pnm_file].to_s
        return result
      when '.png'
        frompnm << " -alpha #{result[:pnm_alpha_file].to_s.inspect}" if result[:pnm_alpha_file]
      end

      result[:dst_file] = dst.keep_tmpfile!(dst.file_or_tmp)
      frompnm << " #{result[:pnm_file].to_s.inspect} > #{result[:dst_file].to_s.inspect}"
      
      cmds << frompnm

      result
    end


    def delete_tmpfiles!
      @src.delete_tmpfiles!
      @dst.delete_tmpfiles!
    end


    # Represents convertable content.
    class Content
      # Identity hooks.
      attr_accessor :id, :uuid

      attr_accessor :file, :name, :directory, :suffix, :data, :md5sum, :mime_type, :options

      attr_accessor :verbose

      # Delegates all other methods to this object.
      # Contenter ContentConversion uses Content models as the delegate.
      attr_accessor :_delegate

      attr_accessor :content_key
      def content_key
        @content_key || @_delegate.content_key
      end

      def method_missing sel, *args, &blk
        if @_delegate
          @_delegate.send(sel, *args, &blk)
        else
          super
        end
      end

      def self.coerce x
        case x
        when Content
          x
        when Hash
          new(x)
        when String
          new(:data => x)
        when Pathname
          new(:file => x)
        else
          raise TypeError
        end
      end

      def initialize opts = nil
        @verbose = false
        @tmpfile = { }
        opts ||= EMPTY_HASH
        opts.each do | k, v |
          send("#{k}=", v)
        end
        @options ||= { }
        @file &&= Pathname.new(@file)
        @mime_type &&= @mime_type.to_s
        # $stderr.puts "new #{opts.inspect} => #{self.inspect}"
      end

      def file_or_tmp name = nil, fill = false
        name ||= @name
        @file ||=
          file ||
          begin
            fn = tmpfile(name, suffix)
            if fill && @data
              File.open(fn, "w+") { | fh | fh.write @data }
            end
            fn
          end
      end

      @@tmpfile_id ||= 0

      def tmpfile(name, suffix = nil)
        name ||= @name
        name = name.to_s
        suffix = suffix.to_s
        @tmpfile[name + suffix] ||=
          begin
            fn = Tempfile.new([ "conconv_" + name, suffix ]).path
            $stderr.puts "    tmpfile(#{name.inspect}, #{suffix.inspect}) => #{fn.inspect}" if @verbose
            Pathname.new(fn)
          end
      end

      def keep_tmpfile! file
        @tmpfile.each do | k, v |
          if v.to_s == file.to_s
            @tmpfile.delete(k)
            break
          end
        end
        file
      end

      def delete_tmpfiles!
        @tmpfile.values do | f |
          File.unlink(f.to_s) rescue nil
        end
        @tmpfile.clear
      end

      MIME_TEXT_PLAIN = 'text/plain'.freeze
      MIME_TEXT_HTML = 'text/html'.freeze
      MIME_IMAGE_JPEG = 'image/jpeg'.freeze
      MIME_IMAGE_X_PORTABLE = 'image/x-portable'.freeze

      def mime_type
        @mime_type ||= 
          case 
          when @suffix
            case @suffix.downcase
            when '.txt'
              MIME_TEXT_PLAIN
            when '.htm', '.html'
              MIME_TEXT_HTML
            when '.jpg'
              MIME_IMAGE_JPEG
            when '.png', '.jpeg', '.gif'
              "image/#{@suffix.sub(/^\./, '')}"
            when '.pnm', '.pgm'
              MIME_IMAGE_X_PORTABLE
            else
              raise ArgumentError, "#{@suffix.inspect}"
            end
          when @file || @data
            compute_mime_type(file_or_data)            
          end
      end

      def image_size
        unless @options[:width] && @options[:height]
          h = compute_image_size(file_or_data)
          @options.update(h) if h
        end
        @options.project(:width, :height)
      end

      def image_size= opts
        @options[:width] = opts && opts[:width]
        @options[:height] = opts && opts[:height]
      end

      def image_supports_alpha?
        mime_type == 'image/png' ||
          mime_type == 'image/gif'
      end

      def md5sum
        @md5sum ||=
          compute_md5sum(file_or_data)
      end

      def suffix
        @suffix ||=
          case
          when @file
            (File.basename(@file.to_s) =~ /(\.[^.\/]*)\Z/) && $1
          end || compute_suffix
      end

      def name
        @name ||=
          case 
          when @file
            File.basename(@file.to_s).sub(/\.[^.\/]*\Z/, '')
          else
            object_id.to_s ### PUNT?
          end
      end

      def file= x
        @data = @md5sum = nil if x
        @file = x && Pathname.new(x)
      end

      def file
        @file ||=
          @directory && @name && @suffix &&
          Pathname.new(
          case mime_type
          when /image/
            if options[:width] || options[:height]
              "#{directory}/#{name}-#{options[:width]}x#{options[:height]}#{suffix}"
            else
              "#{directory}/#{name}#{suffix}"
            end
          else
            "#{directory}/#{name}#{suffix}"
          end
          )
      end

      # Returns an existing Pathname to a file or String data.
      def file_or_data
        @file && File.exists?(@file.to_s) ? @file : @data
      end

      # Forces writing to data to a file.
      def force_to_file
        if @data && ! (@file && File.exist?(@file.to_s))
          fh = Tempfile.new([ "conconv_force_to_file", @suffix.to_s ])
          @force_to_file = @file = Pathname.new(fh.path)
          fh.write @data
          fh.close
          $stderr.puts " force_to_file wrote #{@data.size} => #{fh.path.inspect}" if @verbose
        end
        @file
      end

      # Content model duck-quacking.
      def filename
        file && File.basename(file)
      end

     def directory
        @directory ||=
          @file && File.dirname(@file.to_s)
      end


      def file_type
        @file_type ||=
          compute_file_type(file_or_data)
      end


      def data
        @data ||=
          file && File.exist?(file.to_s) && File.read(file.to_s)
      end

      # invalidates force_to_file and md5sum.
      def data= x
        if @force_to_file
          File.unlink(@force_to_file.to_s) rescue nil
          @force_to_file = @file = nil
        end
        @md5sum = nil
        @data = x
      end

      def unlink!
        file && 
          File.unlink(file.to_s) rescue nil
      end

      ####################################


      def compute_suffix mt = nil
        mt ||= mime_type
        case mt
        when MIME_TEXT_PLAIN
          '.txt'
        when MIME_TEXT_HTML
          '.html'
        when 'image/jpeg'
          '.jpeg'
        when 'image/png'
          '.png'
        when 'image/gif'
          '.gif'
        when /image\/x-portable/
          '.pnm'
        else
          raise ArgumentError, "#{mt.inspect}"
        end
      end


      def compute_mime_type src
        case ft = compute_file_type(src)
        when /: ASCII\b/
          MIME_TEXT_PLAIN
        when /: HTML\b/
          MIME_TEXT_HTML
        when /(\w+) image/
          type = "image/#{$1.downcase}"
          # Extract width and height now, if possible.
          if ft =~ /, (\d+) x (\d+)/
            options[:width] ||= $1.to_i
            options[:height] ||= $2.to_i
          end
          type
        else
          MIME_TEXT_PLAIN # "application/x"
        end
      end


      def compute_file_type src
        src && 
        case src
        when Pathname
          File.exist?(src.to_s) && cmd_out("#{BIN_PREFIX}file #{src.to_s.inspect}")
        else
          compute_file_type(force_to_file)
        end
      end


      # Requires: sudo cpan install Image::Size.
      def compute_image_size src
        $stderr.puts "c_i_s #{src.class} #{src.to_s.size} #{src.inspect}" if src.to_s.size < 1024
        case src
        when Pathname
          # @verbose = true
          result = cmd_out("#{BIN_PREFIX}imgsize -r #{src.to_s.inspect}")
          result = /(\d+) (\d+)/.match(result)
          result = result ? { :width => result[1].to_i, :height => result[2].to_i } : nil
          result
        when String
          compute_image_size(force_to_file)
        else
          raise TypeError, "#{src.class}"
        end
      end


      def compute_md5sum src
        case src
        when Pathname
          cmd_out("#{BIN_PREFIX}md5sum #{src.to_s.inspect}").split(/\s+/).first.downcase
        when String
          Digest::MD5.new.hexdigest(self.data).downcase
        else
          # raise TypeError, "#{src.class}"
          nil
        end
      end


      def cmd_out cmd
        # @verbose = true
        $stderr.puts "`" + cmd + "`" if @verbose
        result = `#{cmd}`
        $stderr.puts result if @verbose
        result
      end

    end # class
  end # class
end # module

