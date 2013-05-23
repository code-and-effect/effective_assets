# This is a join table for assets and acts_as_attachable

class Attachment < ActiveRecord::Base
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
