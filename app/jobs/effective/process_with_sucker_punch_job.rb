require 'sucker_punch'

module Effective
  class ProcessWithSuckerPunchJob
    include ::SuckerPunch::Job

    def perform(id)
      ActiveRecord::Base.connection_pool.with_connection do
        asset = id.kind_of?(Effective::Asset) ? id : Effective::Asset.where(id: (id.to_i rescue 0)).first
        asset.process! if asset
      end
    end

  end
end
