class AssetUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :fog

  def store_dir
    "assets/#{model.id}"
  end

  # resize_to_fit
  # Resize the image to fit within the specified dimensions while retaining the
  # original aspect ratio. The image may be shorter or narrower than specified in the smaller dimension
  # but will not be larger than the specified values.
  #
  # Probably best for taking a big image and making it smaller.
  # Keeps the aspect ratio
  # An uploaded image that is smaller will not be made bigger.

  # resize_to_fill
  # Resize the image to fit within the specified dimensions while retaining the
  # aspect ratio of the original image. If necessary, crop the image in the larger dimension.

  # resize_to_limit
  # http://stackoverflow.com/questions/8570181/carrierwave-resizing-images-to-fixed-width
  # Keep in mind, resize_to_fit will scale up images if they are smaller than 100px.
  # If you don't want it to do that, then replace that with resize_to_limit.

  version :thumb, :if => :image? do
    process :resize_to_fit  => [256,70]
    process :record_info => :thumb
  end

  version :full_page, :if => :image? do
    process :resize_to_limit => [940,nil]
    process :record_info => :full_page
  end

  version :main_column, :if => :image? do
    process :resize_to_limit => [615, nil]
    process :record_info => :main_column
  end

  version :carousel, :if => :image? do
    process :resize_to_limit => [540, 300]
    process :record_info => :carousel
  end

  version :sidebar, :if => :image? do
    process :resize_to_limit => [265, nil]
    process :record_info => :sidebar
  end

  # KEEP THIS UPDATED to match whatever versions and image resizing we're doing above
  def vers
    {
      :thumb => {:width => 128, :height => 128},
      :full_page => {:width => 940, :height => nil},
      :main_column => {:width => 615, :height => nil},
      :carousel => {:width => 540, :height => 300},
      :sidebar => {:width => 265, :height => nil}
    }
  end

  protected

  # record_info
  # Messy hash merging to a serialized field.
  # It has the effect of setting asset.versions_info to a Hash, such as
  #---
  # :medium:
  #   :data_size: 22259
  #   :height: 400
  #   :width: 400
  # :thumb:
  #   :data_size: 3105
  #   :height: 128
  #   :width: 128

  def record_info(version)
    if model and model.respond_to?(:versions_info) and @file.present?
      info = {}
      info[:data_size] = @file.size

      img = MiniMagick::Image.open(@file.file)
      info[:width] = img[:width]
      info[:height] = img[:height]

      model.versions_info.merge!({version.to_sym => info})
    end
  end

  def image?(new_file)
    new_file.present? and new_file.content_type.present? and new_file.content_type.include? 'image' and !(new_file.content_type.include? 'icon')
  end
end

