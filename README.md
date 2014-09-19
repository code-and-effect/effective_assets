# Effective Assets

A Rails Engine full solution for managing assets (images, files, videos, etc).

Attach one or more assets to any model with validations.

Includes an upload direct to Amazon S3 implementation based on jQuery-File-Upload and image processing in the background with CarrierWave and DelayedJob

Both Formtastic and SimpleForm inputs for displaying, organizing, and uploading assets direct to S3.

Works with AWS public-read and authenticated-read for easy secured downloads.

Includes (optional but recommended) integration with ActiveAdmin

Rails 3.2.x and Rails4 support

# Getting Started

Add to your Gemfile:

```ruby
gem 'effective_assets', :git => 'https://github.com/code-and-effect/effective_assets'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_assets:install
```

The generator will install an initializer which describes all configuration options and creates two database migrations, one for EffectiveAssets the other for DelayedJob.

If you want to tweak the table name (to use something other than the default 'assets' and 'attachments'), manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

If you intend to use the form helper method to display and upload assets, require the javascript in your application.js

```ruby
//= require effective_assets
```

If you intend to use ActiveAdmin (optional, but highly recommended)

Add to your ActiveAdmin.js file:

```ruby
//= require effective_assets
```

And to your ActiveAdmin stylesheet

```ruby
body.active_admin {
}
@import "active_admin/effective_assets";
```

If ActiveAdmin is installed, there will automatically be an 'Effective Assets' page.

# Create/Configure an S3 Bucket

You will need an AWS IAM user with sufficient priviledges and a properly configured S3 bucket to use with effective_assets

## Log into AWS Console

- Visit http://aws.amazon.com/console/
- Click My Account from top-right and sign in with your AWS account.

## Create an S3 Bucket

- Click Services -> S3 from the top-left menu
- Click Create Bucket
  - Give the Bucket a name, and select the US Standard region

## Configure CORS Permissions

- From the S3 All Buckets Screen (as above)

- Select the desired bucket to configure and select 'Properties'
- Expand Permissions
- Click 'Edit CORS Configuration' and enter the following

```xml
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>POST</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
  </CORSRule>
  <CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
  </CORSRule>
</CORSConfiguration>
```

- Click Save

The Bucket is now set up and ready to accept uploads, but we still need a user that has permission to access S3

## Create an IAM User and record its AWS Access Keys

- After logging in to your AWS console

- Click Services -> IAM from the top-left

- Select Users from the left-side menu
- Click Create New Users
- Create just one user with any name

- Expand the Show User Security Credentials
- This displays the AWS Access Key and Secret Access Key.
- (important) These are the two values you should copy into the effective_assets.rb initializer file

- Once the user is created, Click on the User and find the Permissions tab
- Select Permissions tab
- Click Attach User Policy
- Scroll down and Select 'Amazon S3 Full Access'

This user is now set up and ready to access the S3 Bucket previously created

## Add S3 Access Keys

Add the name of your S3 Bucket, Access Key and Secret Access Key to the config/initializers/effective_assets.rb file.

```ruby
config.aws_bucket = 'my-bucket'
config.aws_access_key_id = 'ABCDEFGHIJKLMNOP'
config.aws_secret_access_key = 'xmowueroewairo74pacja1/werjow'
```

You should now be able to upload to this bucket.


# Usage

## Model

Use the 'acts_as_asset_box' mixin to define a set of 'boxes' all your assets fall into.  A box is just a category, which can have any name.

If the box is declared as a singular, 'photo', then it will be a singular asset.  When defined as a plural, 'photos', it will be a set of photos.

The following will create 4 separate sets of assets:

```ruby
class User
  acts_as_asset_box :avatar, :photos, :videos, :mp3s
end
```

Calling @user.avatar will return a single Effective::Asset.  Calling @user.photos will return an array of Effective::Assets

To use with validations:

```ruby
class User
  acts_as_asset_box :avatar => true, :photos => false, :videos => 2, :mp3s => 5..10
end
```

The user in this example is only valid if exists an avatar, 2 videos, and 5..10 mp3s.

## Uploading & Attaching

Use the custom Formtastic input for uploading (direct to S3) and attaching assets to the 'pictures' box.

```ruby
= f.input :pictures, :as => :asset_box, :uploader => true

= f.input :pictures, :as => :asset_box, :limit => 2, :file_types => [:jpg, :gif, :png], :attachment_style => :table

= f.input :pictures, :as => :asset_box, :dialog => true, :dialog_url => '/admin/effective_assets' # Use the attach dialog
```

Use the custom SimpleForm input for uploading (direct to S3) and attaching assets to the 'pictures' box.

```ruby
= f.input :pictures, :as => :asset_box_simple_form, :uploader => true

= f.input :pictures, :as => :asset_box_simple_form, :limit => 2, :file_types => [:jpg, :gif, :png]

= f.input :pictures, :as => :asset_box_simple_form, :dialog => true, :dialog_url => '/admin/effective_assets' # Use the attach dialog
```

You may also upload secure (AWS: 'authenticated-read') assets with the same uploader

```ruby
= f.input :pictures, :as => :asset_box_simple_form, :aws_acl => 'authenticated-read'
```

There is also a mechanism for collecting additional information from the upload form which will be set in the asset.extra field.
This is still experimental.

```ruby
= semantic_form_for Product.new,  do |f|
  = f.input :photos, :as => :asset_box
  = f.semantic_fields_for :photos do |upload|
    = upload.input :field1, :as => :string
    = upload.input :field2, :as => :boolean
```

Here the semantic_fields_for will create some inputs with name

```ruby
product[photos][field1]
product[photos][field2]
```

Any additional field like this will be passed to the Asset and populate the 'extra' Hash attribute


Note: Passing :limit => 2 will have no effect on a singular asset_box, which by definition has a limit of 1.

We use the jQuery-File-Upload gem for direct-to-s3 uploading.  The process is as follows:

- User sees the form and clicks Browse.  Selects 1 or more files, then clicks Start Uploading.
- The server makes a post to the S3UploadsController#create action to initialize an asset, and get a unique ID
- The file is uploaded directly to its 'final' resting place on S3 via Javascript uploader. "assets/:id/filename"
- A put is then made back to the S3UploadsController#update which updates the Asset object and sets up a task in DelayedJob to process the asset (for image resizing)
- An attachment is created, which joins the Asset to the parent Object (User in our example) in the appropriate position.
- The DelayedJob task should be running and will handle any image resizing as defined by the AssetUploader
- The asset will appear in the form, and the user may click&drag the asset around to set the position.


## Strong Parameters

Make your controller aware of the acts_as_asset_box passed parameters:

```ruby
def permitted_params
  params.require(:base_object).permit(:attachments_attributes => [:id, :asset_id, :attachable_type, :attachable_id, :position, :box, :_destroy])
end
```

## Image Processing and Resizing

CarrierWave is used under the covers to do all the image resizing.
The installer created an uploaders/asset_uploader.rb which you can use to set up versions.

Some additional processing goes on to record final image dimensions and file sizes.

If the uploader is changed, you can run this rake task to reprocess all assets

```ruby
bundle exec rake reprocess_assets
```

or start at a specific ID (and go up)

```ruby
bundle exec rake reprocess_assets[200]
```

or as a range

```ruby
bundle exec rake reprocess_assets[1, 300]
```

or for an individual asset

```ruby
@asset = Effective::Asset.find(1)
@asset.reprocess!
```

## Helpers

To just get the URL of an asset

```ruby
@asset = @user.fav_icon
@asset.url
  => "http://aws_bucket.s3.amazonaws.com/assets/1/my_favorite_icon.png"
@asset.url(:thumb)
  => "http://aws_bucket.s3.amazonaws.com/assets/1/thumb_my_favorite_icon.png"
```

To display the asset as a link with an image (if its an image, or a mime-type appropriate icon if its not an image):

```ruby
# Asset is the @user.fav_icon
# version is anything you set up in your uploaders/asset_uploader.rb as versions.  :thumb
# Options are passed through to a call to rails image_tag helper
effective_asset_image_tag(asset, version = nil, options = {})
```

To display the asset as a link with no image

```ruby
# Options are passed through to rails link_to helper
effective_asset_link_to(asset, version = nil, options = {})
```

# Authorization

All authorization checks are handled via the config.authorization_method found in the config/initializers/ file.

It is intended for flow through to CanCan or Pundit, but that is not required.

This method is called by all controller actions with the appropriate action and resource

Action will be one of [:index, :show, :new, :create, :edit, :update, :destroy]

Resource will the appropriate Effective::Something ActiveRecord object or class

The authorization method is defined in the initializer file:

```ruby
# As a Proc (with CanCan)
config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) }
```

```ruby
# As a Custom Method
config.authorization_method = :my_authorization_method
```

and then in your application_controller.rb:

```ruby
def my_authorization_method(action, resource)
  current_user.is?(:admin) || EffectivePunditPolicy.new(current_user, resource).send('#{action}?')
end
```

or disabled entirely:

```ruby
config.authorization_method = false
```

If the method or proc returns false (user is not authorized) an Effective::AccessDenied exception will be raised

You can rescue from this exception by adding the following to your application_controller.rb:

```ruby
rescue_from Effective::AccessDenied do |exception|
  respond_to do |format|
    format.html { render 'static_pages/access_denied', :status => 403 }
    format.any { render :text => 'Access Denied', :status => 403 }
  end
end
```

# License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect

# Credits

This gem heavily relies on:

CarrierWave (https://github.com/carrierwaveuploader/carrierwave)

DelayedJob (https://github.com/collectiveidea/delayed_job)

jQuery-File-Upload (https://github.com/blueimp/jQuery-File-Upload)


# Testing

Testing uses the Combustion gem, for easier Rails Engine Testing.

https://github.com/pat/combustion

You will need a valid initializer in spec/internal/config/initializers/effective_assets.rb

Run tests by

```ruby
bundle exec guard
```
