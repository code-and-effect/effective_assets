require 'sucker_punch'

module Effective
  class ProcessAssetJob
    include ::SuckerPunch::Job

    def perform(obj)
      ActiveRecord::Base.connection_pool.with_connection do
        asset = obj.kind_of?(Effective::Asset) ? obj : Effective::Asset.where(id: (obj.to_i rescue 0)).first
        asset.process! if asset
      end
    end

  end
end
