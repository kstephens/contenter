
# Represents the cached conversion of content from one type to another.
class ContentConversion < ActiveRecord::Base
  include UuidModel
  include UserTracking

  [ :src, :dst ].each do | x |
    validates_format_of :"#{x}_uuid", :with => Contenter::Regexp.uuid, :allow_nil => true

    validates_presence_of :"#{x}_mime_type"

    validates_presence_of :"#{x}_data_md5sum"
    validates_length_of :"#{x}_data_md5sum", :is => 32
    validates_format_of :"#{x}_data_md5sum", :with => Contenter::Regexp.md5sum
  end

  before_validation :initialize_md5sum!

  # Convert from one content type to another.
  def self.convert(src, dst)
    conversion = nil

    verbose = Hash === dst && dst.delete(:verbose)

    conditions = conditions_for(src, dst)
    $stderr.puts "conditions = #{conditions.inspect}" if verbose

    self.transaction do
      unless conversion = self.find(:first, :conditions => conditions)
        src_c = dst_c = nil
        begin
          src_c = src
          unless Contenter::ContentConverter::Content === src_c
            src_c = Contenter::ContentConverter::Content.new(:data => src.data, 
                                                             :mime_type => src.mime_type.to_s)
          end
          dst_c = Contenter::ContentConverter::Content.new(:mime_type => conditions[:dst_mime_type].to_s,
                                                           :options => dst[:options])
          
          converter = Contenter::ContentConverter.new(:src => src_c, :dst => dst_c)
          converter.verbose = verbose
          converter.convert!
          # pp converter
         
          # $stderr.puts "self.columns = "; pp self.columns

          conversion = 
            self.create!(:src_uuid => conditions[:src_uuid],
                         :src_data => src_c.data, 
                         :src_data_md5sum => src_c.md5sum,
                         :src_mime_type => src_c.mime_type.to_s,
                         :dst_uuid => conditions[:dst_uuid],
                         :dst_data => dst_c.data,
                         :dst_data_md5sum => dst_c.md5sum,
                         :dst_mime_type => dst_c.mime_type.to_s,
                         :dst_options => conditions[:dst_options])

          raise Error, "#{conversion.errors.to_s}" unless conversion.errors.empty?
        ensure
          dst_c.unlink! if dst_c
        end
      end
    end
    conversion.content
  end

  # Destroys all conversions that match src.
  def self.invalidate_src!(src)
    conditions = conditions_for(src)
    if conditions[:src_uuid]
      connection.execute("DELETE FROM #{table_name} WHERE src_uuid = %s" % 
                         [ connection.quote(conditions[:src_uuid]) ]
                         )
    else
      connection.execute("DELETE FROM #{table_name} WHERE src_data_md5sum = %s and src_mime_type = %s" %
                         [ conditions[:src_data_md5sum],
                           conditions[:src_mime_type], 
                         ].map{|x| connection.quote(x)}
                         )
    end
  end

  def self.conditions_for src, dst = nil, conditions = nil
    conditions ||= { }

    conditions[:src_uuid] = src.uuid if src.respond_to?(:uuid)
    conditions[:src_data_md5sum] = src.md5sum if src.respond_to?(:md5sum)
    conditions[:src_mime_type] = src.mime_type.to_s if src.respond_to?(:mime_type)
    conditions.merge(src) if Hash === src

    if dst
      conditions[:dst_uuid] = dst.uuid if dst.respond_to?(:uuid)

      suffix = dst.suffix.to_s if dst.respond_to?(:suffix)
      suffix = dst.delete(:suffix) if Hash === dst
      if suffix
        conditions[:dst_mime_type] ||= Contenter::ContentConverter::Content.new(:suffix => suffix).mime_type
      end

      conditions[:dst_mime_type] ||= dst.mime_type.to_s if dst.respond_to?(:mime_type)
      conditions[:dst_mime_type] ||= dst.delete(:mime_type) if Hash === dst
      conditions[:dst_mime_type] = conditions[:dst_mime_type].to_s
      
      conditions[:dst_options] = encode_options(dst[:options]) if Hash === dst
    end

    conditions
  end

  EMPTY_HASH = { }.freeze

  def self.encode_options hash = nil
    hash ||= EMPTY_HASH
    return hash if String === hash
    s = '{'
    s << hash.keys.sort_by{| k | k.to_s}.map{| k | "#{k.to_sym.inspect}=>#{hash[k].inspect}"}.join(',')
    s << '}'
    s
  end

  # Returns a Content object that represents the conversion.
  def content
    @content ||=
      Contenter::ContentConverter::Content.new(:id => self.id,
                                               :uuid => self.uuid,
                                               :data => self.dst_data, 
                                               :md5sum => self.dst_data_md5sum, 
                                               :mime_type => self.dst_mime_type
                                               )
  end

  EMPTY_STRING = ''.freeze
  EMPTY_OPTIONS = '{}'.freeze

  def initialize_md5sum!
    self.src_options ||= EMPTY_OPTIONS
    self.src_data ||= EMPTY_STRING
    self.dst_data ||= EMPTY_STRING
    self.src_data_md5sum ||= Digest::MD5.new.hexdigest(self.src_data).downcase
    self.dst_data_md5sum ||= Digest::MD5.new.hexdigest(self.dst_data).downcase
  end
  
end




