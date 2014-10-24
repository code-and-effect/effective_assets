module EffectiveAssetsHelper
  # Generates an image tag based on the particular asset
  def effective_asset_image_tag(asset, version = nil, options = {})
    if asset.image? == false
      opts = {}
    elsif version.present? and asset.versions_info[version].present?
      opts = { :height => asset.versions_info[version][:height], :width => asset.versions_info[version][:width] }
    elsif version.present? and asset.data.respond_to?(:versions_info) and asset.data.versions_info[version].present?
      opts = { :height => asset.data.versions_info[version][:height], :width => asset.data.versions_info[version][:width] }
    elsif asset.height.present? and asset.width.present?
      opts = { :height => asset.height, :width => asset.width }
    else
      opts = {}
    end

    opts = opts.merge({:alt => asset.description || asset.title || asset.file_name}).merge(options)
    image_tag(_effective_asset_image_url(asset, version), opts).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
  end

  def effective_asset_link_to(asset, version = nil, options = {})
    options_title = options.delete(:title)
    link_title = options_title || asset.title || asset.file_name || asset.description || "Asset ##{asset.id}"

    if asset.image?
      link_to(link_title, _effective_asset_image_url(asset, version), options).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
    else
      link_to(link_title, asset.url, options).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
    end
  end

  def effective_asset_video_tag(asset)
    render(:partial => 'assets/video', :locals => { :asset => asset }).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
  end

  def effective_asset_title(asset)
    [
      asset.title,
      asset.description,
      asset.tags,
      "Size: #{number_to_human_size(asset.data_size)}",
      "Content Type: #{asset.content_type}"
    ].compact.join("\n")
  end

  def _effective_asset_image_url(asset, version = nil)
    return asset_url('mime-types/file.png') if !asset.content_type.present? or asset.content_type == 'unknown'

    if asset.icon?
      asset.url
    elsif asset.image?
      asset.url(version)
    elsif asset.audio?
      asset_url('mime-types/mp3.png')
    elsif asset.video?
      asset_url('mime-types/video.png')
    elsif asset.content_type.include? 'msword'
      asset_url('mime-types/word.jpg')
    elsif asset.content_type.include? 'excel'
      asset_url('mime-types/excel.png')
    elsif asset.content_type.include? 'application/pdf'
      asset_url('mime-types/pdf.png')
    elsif asset.content_type.include? 'application/zip'
      asset_url('mime-types/zip.png')
    else
      asset_url('mime-types/file.png')
    end
  end
end
