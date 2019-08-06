EffectiveAssets.setup do |config|
  config.assets_table_name = :assets
  config.attachments_table_name = :attachments
  config.iframe_uploads_table_name = :iframe_uploads

  config.uploader = 'AssetUploader'   # Must extend from EffectiveAssetsUploader

  # Authorization Method
  #
  # This method is called by all controller actions with the appropriate action and resource
  # If the method returns false, an Effective::AccessDenied Error will be raised (see README.md for complete info)
  #
  # Use via Proc (and with CanCan):
  # config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) }
  #
  # Use via custom method:
  # config.authorization_method = :my_authorization_method
  #
  # And then in your application_controller.rb:
  #
  # def my_authorization_method(action, resource)
  #   current_user.is?(:admin)
  # end
  #
  # Or disable the check completely:
  # config.authorization_method = false
  config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) } # CanCanCan

  # This is your S3 bucket information
  config.aws_bucket = ''              # ENV.fetch('AWS_S3_BUCKET')
  config.aws_access_key_id = ''       # ENV.fetch('AWS_ACCESS_KEY_ID')
  config.aws_secret_access_key = ''   # ENV.fetch('AWS_SECRET_ACCESS_KEY')
  config.aws_region = 'us-east-1'     # ENV.fetch('AWS_REGION') # ca-central-1

  config.aws_path = 'assets/'

  # This is the default aws_acl all assets will be created with
  # Unless you override the value by passing :aws_acl => '' to the asset_box_input, Asset.create_from_url, or Asset.create_from_string
  # Valid settings are public-read, authenticated-read
  config.aws_acl = 'public-read'

  # Register Effective::Asset with ActiveAdmin if ActiveAdmin is present
  config.use_active_admin = true
end
