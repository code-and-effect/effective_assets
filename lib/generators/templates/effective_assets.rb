# EffectiveAssets Rails Engine

EffectiveAssets.setup do |config|
  # This is your S3 bucket information
  config.aws_bucket = ''
  config.aws_access_key_id = ''
  config.aws_secret_access_key = ''

  config.aws_final_path = 'assets/'
  config.aws_upload_path = 'uploads/'
  config.aws_acl = 'public-read'
end
