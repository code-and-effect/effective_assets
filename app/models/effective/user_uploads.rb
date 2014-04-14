# This is a class used for the EffectiveMercury All User Assets display

module Effective
  class UserUploads < ActiveRecord::Base
    acts_as_asset_box :uploads

    def initialize(user = nil)
      super()
      @column_types = {}

      add_to_asset_box(:uploads, Effective::Asset.where(:user_id => user.id)) if user.present?
    end

    def self.columns
      @columns ||= []
    end

  end
end
