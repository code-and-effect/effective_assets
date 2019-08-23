if defined?(EffectiveRegions)
  module Effective
    module Snippets
      class EffectiveAsset < Snippet
        # attr_accessor :asset_id     #, Integer
        # attr_accessor :html_class   #, String
        # attr_accessor :link_title   #, String
        # attr_accessor :private_url  # , Boolean

        def snippet_attributes
          super + [:asset_id, :html_class, :link_title, :private_url]
        end

        def asset
          @asset ||= (Effective::Asset.where(:id => asset_id).first if asset_id)
        end

        def snippet_tag
          :span
        end

        def private_url
          super || aws_private?
        end

        def is_private?
          [true, 'true', '1'].include?(private_url)
        end

        def aws_private?
          (asset.try(:aws_acl) == EffectiveAssets::AWS_PRIVATE)
        end

      end
    end
  end
end
