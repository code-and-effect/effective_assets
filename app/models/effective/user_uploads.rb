# This is a class used for the IFrame views

module Effective
  class UserUploads < ActiveRecord::Base
    acts_as_asset_box :uploads

    def initialize(assets = nil)
      super()
      @column_types = {}

      add_to_asset_box(:uploads, Array(assets))
    end

    def self.columns
      @columns ||= []
    end

  end
end
