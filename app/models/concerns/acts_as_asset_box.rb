# ActsAsAssetBox
#
# Returns a set of assets or one asset as defined by the provided 'boxes' (a box is just a category) array
# Works with Formtastic::Inputs::asset_box_input
#
# Define your model with 'acts_as_asset_box' if you just need one box of assets
# You will then be able to call @my_resource.assets and @my_resource.asset
#
# or
#
# acts_as_asset_box :fav_icon, :pictures, :logos
#
# or (if you want validations)
#
# acts_as_asset_box :fav_icon => true, :pictures => false, :videos => 2, :images => 5..10
#
# Define your model with 'acts_as_asset_box :fav_icon, :pictures, :logos' for 3 different boxes of assets.
# This creates three methods, @my_resource.fav_icon, @my_resource.pictures, @my_resource.logos
#
# If you define a singular name, like :fav_icon, then calling @my_resource.fav_icon will return the 1 asset from the fav_icon box
# If you define a plural name, like :pictures, then calling @my_resource.pictures will return all assets in the pictures box
#
# This works with the lib/acts_as_asset_box_input.rb for editting boxes of assets
#

module ActsAsAssetBox
  extend ActiveSupport::Concern

  module ActiveRecord
    def acts_as_asset_box(*options)
      @acts_as_asset_box_opts = options || []
      include ::ActsAsAssetBox
    end
  end

  included do
    has_many :attachments, :as => :attachable, :class_name => "Effective::Attachment", :dependent => :delete_all
    has_many :assets, :through => :attachments, :class_name => "Effective::Asset"

    accepts_nested_attributes_for :attachments, :reject_if => :all_blank, :allow_destroy => true

    # Setup validations
    boxes = @acts_as_asset_box_opts.try(:flatten) || []
    if boxes.first.kind_of?(Hash) # We were passed some validation requirements
      boxes = boxes.first

      boxes.each do |box, validation|
        self.send(:define_method, box) { assets(box) }

        if validation == true
          validates box, :asset_box_presence => true
        elsif validation.kind_of?(Integer) or validation.kind_of?(Range)
          validates box, :asset_box_length => validation
        end
      end
    else
      boxes.each do |key|
        self.send(:define_method, key) { assets(key) }
      end
    end

    class_eval do
      def attachments_attributes=(atts)
        current_box = ''; position = 0

        atts.each do |k, v|
          (current_box = v['box'] and position = 0) if v['box'] != current_box
          atts[k]['position'] = (position += 1) if atts[k]['_destroy'] != '1'
        end

        assign_nested_attributes_for_collection_association(:attachments, atts, {})
      end
    end
  end

  module ClassMethods
  end

  def assets(box = nil)
    box = (box.present? ? box.to_s : 'assets')

    if box == box.pluralize
      attachments.select { |attachment| attachment.box == box }.map { |attachment| attachment.asset }
    else
      attachments.to_a.find { |attachment| attachment.box == box.pluralize }.try(:asset)
    end
  end

  def asset
    assets(:asset)
  end

end

