
#
# Represents a unique MIME type.
#
# '_' can be used as a wildcard.
#
class MimeType < ActiveRecord::Base
  include ContentModel
  include AuxDataModel
  include ContentAxis

  validates_format_of :code, 
  :with => /\A_|([a-z_][-a-z0-9_]*|\*)\/([a-z_][-a-z0-9_]*|\*)\Z/,
  :message => "#{self.name} code is invalid"
  validates_uniqueness_of :code

  belongs_to :mime_type_super, :class_name => 'MimeType'

  # Returns a list of all mime_type_super ancestors (including self).
  def mime_type_ancestors
    @mime_type_ancestors ||=
      begin
        result = [ self ]
        stack = [ self.mime_type_super ]
        until stack.empty?
          obj = stack.pop
          next unless obj
          unless result.include?(obj)
            result << obj
            stack.push(obj.mime_type_super)
          end
        end
        result.freeze
      end
  end

  # Returns a list of all mime_types that are subtypes of this.
  def mime_type_decendents
    @mime_type_decendents ||=
      begin
        result = MimeType.find(:all).select{ | x | x.is_a_mime_type?(self) && x.id != self.id }
        result.freeze
      end
  end

  def self.conditions_is_a_mime_type? mt
    "IN (#{mt.mime_type_ancestors.map{|x| x.id}.join(', ')})"
  end

  def self.all_of_mime_type mt
    mt = MimeType[mt]
    mt ? mt.mime_type_decendents : [ ]
  end

  def is_a_mime_type? mt
    mime_type_ancestors.include?(mt)
  end

  def is_image?
    @is_image ||= 
      [ code =~ /\Aimage\// ].first
  end

  def is_audio?
    @is_audio ||= 
      [ code =~ /\Aaudio\// ].first
  end

  def is_text?
    @is_text ||=
      [ code =~ /\Atext\// ].first
  end

  def is_binary?
    @is_binary ||=
      [ is_image? || is_audio? ].first
  end

end

