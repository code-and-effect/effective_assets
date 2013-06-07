module EffectiveAssetsHelper
  def assets_image_url(asset, version = nil)
    return '/assets/mime-types/file.png' if !asset.content_type.present? or asset.content_type == 'unknown'

    if asset.icon?
      asset.url
    elsif asset.image?
      (version == nil or asset.still_processing?) ? asset.url : asset.url.insert(asset.url.rindex('/')+1, "#{version.to_s}_")
    elsif asset.audio?
      '/assets/mime-types/mp3.png'
    elsif asset.video?
      '/assets/mime-types/video.png'
    elsif asset.content_type.include? 'msword'
      '/assets/mime-types/word.jpg'
    elsif asset.content_type.include? 'excel'
      '/assets/mime-types/excel.jpg'
    elsif asset.content_type.include? 'application/pdf'
      '/assets/mime-types/pdf.png'
    elsif asset.content_type.include? 'application/zip'
      '/assets/mime-types/zip.png'
    else
      '/assets/mime-types/file.png'
    end
  end

  # Generates an image tag based on the particular asset
  def assets_image_tag(asset, version = nil, options = {})
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
    image_tag(assets_image_url(asset, version), opts).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
  end

  def assets_file_tag(asset, version = nil, options = {})
    link_title = asset.title || asset.file_name || asset.description || "Asset ##{asset.id}"

    link_to(link_title, url).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
  end

  def assets_video_tag(asset)
    render(:partial => 'assets/video', :locals => { :asset => asset }).gsub('"', "'").html_safe # we need all ' quotes or it breaks Insert as functionality
  end


end
