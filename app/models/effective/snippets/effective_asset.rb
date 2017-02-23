if defined?(EffectiveRegions)
  module Effective
    module Snippets
      class EffectiveAsset < Snippet
        attribute :asset_id, Integer
        attribute :html_class, String
        attribute :link_title, String
        attribute :private_url, Boolean

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
          private_url == true
        end

        def aws_private?
          (asset.try(:aws_acl) == EffectiveAssets::AWS_PRIVATE)
        end

      end
    end
  end
end
