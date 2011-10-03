#coding: utf-8
module UploaderUtils
  extend ActiveSupport::Concern
  
  included do
    attr_accessor :picture_height, :picture_width, :crop_x, :crop_y, :crop_h, :crop_w
    after_update :reprocess_picture, :if => :cropping?    
  end
   
  module ClassMethods
    def upload(attachments)
      cattr_accessor :attachments
      self.attachments = [*attachments]
      send :before_validation, :__set_attachment_attribs
    end
  end
  
  module InstanceMethods
    def cropping?
      !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
    end

    def get_picture_width
      image = MiniMagick::Image.open(File.join(Rails.root, 'public', picture.url(:screen)))
      image[:width]
    end

    def get_picture_height
      image = MiniMagick::Image.open(File.join(Rails.root, 'public', picture.url(:screen)))
      image[:height]
    end
    
    
    private
    
      def reprocess_picture
        true
      end

      def picture_dimensions
        if picture_height and picture_height and picture_width < 100 and picture_height < 100
          errors.add :picture, "ma zbyt małe rozmiary"
        end
      end
    
      def __set_attachment_attribs
        self.class.attachments.each do |attachment|
          if send "#{attachment}?"                 
            send "#{attachment}_file_size=", File.size(send(attachment).file.path)
            send "#{attachment}_content_type=", send(attachment).file.content_type || 
              `file --mime -b #{send(attachment).file.path}`.chomp.split(';').first
            send "#{attachment}_original_file_name=", send(attachment).file.original_filename
          end
        end
      end
  end
end
