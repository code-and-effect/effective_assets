# This is a join table for assets and acts_as_attachable

module Effective
  class Attachment < ActiveRecord::Base
    self.table_name = EffectiveAssets.attachments_table_name.to_s

    belongs_to :asset, class_name: 'Effective::Asset'
    belongs_to :attachable, :polymorphic => true

    # structure do
    #   position        :integer
    #   box             :string, :default => 'assets'  # This is essentially a category
    # end

    default_scope -> { includes(:asset).order(:position).order(:asset_id) }

    validates :asset_id, presence: true
    validates :position, presence: true, numericality: true
    validates :box, presence: true

  end
end
