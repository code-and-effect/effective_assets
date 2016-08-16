# This is a class used for the IFrame views

module Effective
  class IframeUploads < ActiveRecord::Base
    acts_as_asset_box :uploads

    def initialize(items = nil)
      super()
      @column_types = {}

      add_to_asset_box(:uploads, items)
    end

    def self.columns
      @columns ||= []
    end

    def self.column_defaults
      {}
    end

    def self.has_attribute?(*args)
      false
    end

  end
end
