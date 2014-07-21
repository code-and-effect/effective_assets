# EffectiveAssets Rails Engine

EffectiveAssets.setup do |config|
  config.assets_table_name = :assets
  config.attachments_table_name = :attachments

  config.uploader = AssetUploader   # Must extend from EffectiveAssetsUploader

  # This is your S3 bucket information
  config.aws_bucket = ''
  config.aws_access_key_id = ''
  config.aws_secret_access_key = ''

  config.aws_path = 'assets/'

  # This is the default aws_acl all assets will be created with
  # Unless you override the value by passing :aws_acl => '' to the asset_box_input, Asset.create_from_url, or Asset.create_from_string
  # Valid settings are public-read, authenticated-read
  config.aws_acl = 'public-read'

  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) }

  # Register Effective::Asset with ActiveAdmin if ActiveAdmin is present
  config.use_active_admin = true
end
