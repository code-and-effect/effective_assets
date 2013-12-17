class EffectiveAssetsUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :fog

  def store_dir
    "#{EffectiveAssets.aws_path.chomp('/')}/#{model.id.to_i}"
  end

  # Returns a Hash as per the versions above
  # {:thumb=>{:width=>256, :height=>70}, :full_page=>{:width=>940, :height=>nil}}
  def versions_info
    @versions_info ||= calculate_versions_info
  end

  def fog_public
    model.aws_acl == 'public-read' rescue true
  end

  def fog_authenticated_url_expiration
    @fog_authenticated_url_expiration || 10.minutes
  end

  def fog_authenticated_url_expiration=(expires_in)
    @fog_authenticated_url_expiration = expires_in
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
    new_file.present? and new_file.content_type.to_s.include?('image') and !(new_file.content_type.include?('icon'))
  end

  def calculate_versions_info
    retval = {}

    self.class.versions.each do |k, v|
      v[:uploader].processors.each do |processor|
        dimensions = processor[1]

        if processor[0].to_s.include?('resize') and dimensions.kind_of?(Array) and dimensions.length == 2
          retval[k] = {:width => dimensions.first, :height => dimensions.last}
          break
        end
      end
    end

    retval
  end
end
