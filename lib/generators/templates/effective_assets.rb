# EffectiveAssets Rails Engine

EffectiveAssets.setup do |config|
  config.assets_table_name = :assets
  config.attachments_table_name = :attachments

  config.uploader = AssetUploader

  # This is your S3 bucket information
  config.aws_bucket = ''
  config.aws_access_key_id = ''
  config.aws_secret_access_key = ''

  config.aws_path = 'assets/'
  config.aws_acl = 'public-read' # Options are: public-read, authenticated-read can be overridden on the asset_box_input

  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) }
end
