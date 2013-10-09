module EffectiveAssetsS3Helper

  def s3_uploader_fields(options = {})
    S3Uploader.new(options).fields.map do |name, value|
      hidden_field_tag(name, value)
    end.join.html_safe
  end

  def s3_uploader_url
    "https://s3.amazonaws.com/#{EffectiveAssets.aws_bucket}/"
  end

  # Copied and modified from https://github.com/waynehoover/s3_direct_upload/blob/master/lib/s3_direct_upload/form_helper.rb
  class S3Uploader
    def initialize(options)
      @options = options.reverse_merge(
        aws_access_key_id: EffectiveAssets.aws_access_key_id,
        aws_secret_access_key: EffectiveAssets.aws_secret_access_key,
        bucket: EffectiveAssets.aws_bucket,
        acl: EffectiveAssets.aws_acl,
        expiration: 10.hours.from_now.utc.iso8601,
        max_file_size: 1000.megabytes,
        key_starts_with: "#{EffectiveAssets.aws_path.chomp('/')}/",
        key: '${filename}' # We use an AJAX request to update this key to a useful value
      )
    end

    def fields
      {
        :key => @options[:key],
        :acl => @options[:acl],
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
          ['starts-with', '$utf8', ''],
          ['starts-with', '$key', @options[:key_starts_with]],
          ['starts-with', '$x-requested-with', ''],
          ['content-length-range', 0, @options[:max_file_size]],
          ['starts-with','$content-type', @options[:content_type_starts_with] || ''],
          {:bucket => @options[:bucket]},
          {:acl => @options[:acl]},
          {:success_action_status => '201'}
        ] + (@options[:conditions] || [])
      }
    end

    def signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          @options[:aws_secret_access_key], policy
        )
      ).gsub("\n", "")
    end
  end

end
