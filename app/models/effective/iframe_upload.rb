# This is a class used for the IFrame views

module Effective
  class IframeUpload < ActiveRecord::Base
    acts_as_asset_box :uploads

    def initialize(items = nil)
      super()
      add_to_asset_box(:uploads, items)
    end

  end
end
