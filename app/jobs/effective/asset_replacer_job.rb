module Effective
  class AssetReplacerJob < ::ApplicationJob

    queue_as :default

    if defined?(Sidekiq)
      # The retry setting works. But none of these waits seem to. Still getting exponential backoff.
      sidekiq_options retry: 2, retry_in: 10, wait: 10
      sidekiq_retry_in { |count, exception| 10 }
    end

    def perform(attachment, box)
      Effective::AssetReplacer.new.replace_attachment!(attachment, box)
    end

  end
end
