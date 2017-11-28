module EffectiveAssetsS3Helper

  def s3_uploader_fields(options = {})
    S3Uploader.new(options).fields.map do |name, value|
      hidden_field_tag(name, value, disabled: 'disabled')
    end.join.html_safe
  end

  def s3_uploader_input_js_options(options = {})
    {
      url: (Effective::Asset.s3_base_path.chomp('/') + '/'),
      remove_completed_progress_bar: true,
      allow_multiple_files: (options[:limit].to_i > 1),
      file_types: Array(options[:file_types]).flatten.join('|').to_s,
      create_asset_url: effective_assets.s3_uploads_url,
      update_asset_url: "#{effective_assets.s3_uploads_url}/:id",
      click_submit: (options[:click_submit] == true)
    }.to_json()
  end

  # Copied and modified from https://github.com/waynehoover/s3_direct_upload/blob/master/lib/s3_direct_upload/form_helper.rb
  class S3Uploader
    def initialize(options)
      @options = options.reverse_merge(
        aws_access_key_id: EffectiveAssets.aws_access_key_id,
        aws_secret_access_key: EffectiveAssets.aws_secret_access_key,
        bucket: EffectiveAssets.aws_bucket,
        aws_acl: EffectiveAssets.aws_acl,
        expiration: 10.hours.from_now.utc.iso8601,
        max_file_size: 1000.megabytes,
        key_starts_with: "#{EffectiveAssets.aws_path.chomp('/')}/",
        key: '${filename}' # We use an AJAX request to update this key to a useful value
      )
    end

    def fields
      {
        :key => @options[:key],
        :acl => @options[:aws_acl],
        'AWSAccessKeyId' => @options[:aws_access_key_id],
        :policy => policy,
        :signature => signature,
        :success_action_status => '201',
        'X-Requested-With' => 'xhr'
      }
    end

    def policy
      Base64.encode64(policy_data.to_json).gsub("\n", "")
    end

    def policy_data
      {
        expiration: @options[:expiration],
        conditions: [
          ['starts-with', '$key', @options[:key_starts_with]],
          ['starts-with', '$x-requested-with', ''],
          ['content-length-range', 0, @options[:max_file_size]],
          ['starts-with','$content-type', @options[:content_type_starts_with] || ''],
          {:bucket => @options[:bucket]},
          {:acl => @options[:aws_acl]},
          {:success_action_status => '201'}
        ] + (@options[:conditions] || [])
      }
    end

    def signature
      raise 'effective_assets config.aws_secret_access_key is blank. Please provide a value in config/initializers/effective_assets.rb' if @options[:aws_secret_access_key].blank?

      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::SHA1.new(),
          @options[:aws_secret_access_key].to_s, policy
        )
      ).gsub("\n", "")
    end
  end

end
