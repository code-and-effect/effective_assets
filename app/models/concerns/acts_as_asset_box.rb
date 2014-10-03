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
        @last_atts == atts ? return : @last_atts = atts

        current_box = ''; position = 0

        atts.each do |k, v|
          (current_box = v['box'] and position = 0) if v['box'] != current_box
          atts[k]['position'] = (position += 1) if atts[k]['_destroy'] != '1'
        end

        assign_nested_attributes_for_collection_association(:attachments, atts)
      end
    end
  end

  module ClassMethods
  end

  def assets(box = nil)
    box = (box.present? ? box.to_s : 'assets')
    boxes = box.pluralize

    if box == boxes
      attachments.map { |attachment| attachment.asset if attachment.box == boxes }.compact
    else
      attachments.to_a.find { |attachment| attachment.box == boxes }.try(:asset)
    end
  end

  def asset
    assets(:asset)
  end

  def add_to_asset_box(box, *assets)
    box = (box.present? ? box.to_s : 'assets')
    boxes = box.pluralize
    assets = assets.flatten

    unless assets.present? && assets.all? { |obj| obj.kind_of?(Effective::Asset) }
      raise ArgumentError.new('expecting one or more Effective::Assets, or an Array of Effective::Assets')
    end

    if box == boxes # If we're adding to a pluralized box, we want to add our attachment onto the end
      pos = attachments.select { |attachment| attachment.box == boxes }.last.try(:position).to_i + 1
    else # If we're adding to a singular box, we want our attachments to be on the front
      pos = attachments.to_a.find { |attachment| attachment.box == boxes }.try(:position).to_i

      # Push all the attachments forward
      attachments.each { |att| att.position = (att.position + assets.length) if att.box == boxes }
    end

    # Build the attachments
    assets.each_with_index do |asset, x|
      attachment = self.attachments.build(:position => (pos+x), :box => boxes)

      attachment.attachable = self
      attachment.asset = asset
    end

    attachments.to_a.sort_by!(&:position)

    true
  end

  def add_to_asset_box!(box, *assets)
    add_to_asset_box(box, assets) && save!
  end

  # The idea here is that if you want to replace an Asset with Another one
  # the Attachment should keep the same order, and only the asset should change

  def replace_in_asset_box(box, original, overwrite)
    box = (box.present? ? box.to_s : 'assets')
    boxes = box.pluralize

    unless original.present? && original.kind_of?(Effective::Asset)
      raise ArgumentError.new("second parameter 'original' must be a single Effective::Asset")
    end

    unless overwrite.present? && overwrite.kind_of?(Effective::Asset)
      raise ArgumentError.new("third parameter 'overwrite' must be a single Effective::Asset")
    end

    attachment = attachments.to_a.find { |attachment| attachment.box == boxes && attachment.asset == original }

    if attachment.present?
      attachment.asset = overwrite
      true
    else
      false
    end
  end

  def replace_in_asset_box!(box, original, overwrite)
    replace_in_asset_box(box, original, overwrite) && save!
  end

end

