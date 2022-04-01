# Replaces the [snippet_x] in all effective regions with static content

module Effective
  class SnippetReplacer
    include ActiveStorage::Blob::Analyzable
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::AssetTagHelper

    def replace!
      raise('expected effective regions') unless defined?(Effective::Region)
      raise('expected effective assets') unless defined?(Effective::Asset)
      raise('expected active storage') unless defined?(ActiveStorage)

      Effective::Region.with_snippets.find_each do |region|
        Effective::SnippetReplacerJob.perform_later(region)
      end

      puts 'All Done. Background jobs are running. Have a great day.'
      true
    end

    def replace_region!(region)
      region.snippet_objects.each do |snippet|
        print('.')

        begin
          case snippet.class.name
          when 'Effective::Snippets::EffectiveAsset'
            replace_effective_asset(region, snippet)
          else
            raise("unsupported snippet: #{snippet.class.name}")
          end
        rescue => e
          puts "\nError: #{e}\n"
          remove_snippet(region, snippet)
        end
      end

      region.save!
    end

    def replace_effective_asset(region, snippet)
      asset = snippet.asset
      raise("Effective:Asset id=#{snippet.asset_id || 'none'} does not exist") unless asset.present?

      blob = ActiveStorage::Blob.create_and_upload!(io: URI.open(asset.url), filename: asset.file_name)
      url = Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)

      content = if asset.image?
        image_tag(url, class: snippet.html_class, alt: snippet.link_title)
      else
        link_to(snippet.link_title, url, class: snippet.html_class, title: snippet.link_title)
      end

      region.content.sub!("[#{snippet.id}]", content.to_s)
      region.snippets.delete(snippet.id)

      true
    end

    def remove_snippet(region, snippet)
      region.content.sub!("[#{snippet.id}]", '')
      region.snippets.delete(snippet.id)
    end

  end
end
