# This is a join table for assets and acts_as_attachable

module Effective
  class Attachment < ActiveRecord::Base
    self.table_name = EffectiveAssets.attachments_table_name.to_s

    belongs_to :asset
    belongs_to :attachable, :polymorphic => true

    structure do
      position        :integer, :validates => [:presence, :numericality]
      box             :string, :default => 'assets', :validates => [:presence]  # This is essentially a category
    end

    validates_presence_of :asset_id

    #attr_accessible :box, :position, :asset_id, :attachable_type, :attachable_id

    class << self
      def default_scope
        includes(:asset).order(:position)
      end
    end
  end
end
