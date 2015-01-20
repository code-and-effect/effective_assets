# Effective Assets

Upload images and files directly to AWS S3 with a custom form input, then seamlessly organize and attach them to any ActiveRecord object.

A Rails Engine full solution for managing assets (images, files, videos, etc).

Attach one or more assets to any model with validations.

Upload direct to Amazon S3 implementation based on jQuery-File-Upload and image processing on a background process with CarrierWave and DelayedJob

Rails FormBuilder, Formtastic and SimpleForm inputs for displaying, managing, and uploading assets direct to S3.

Works with AWS public-read and authenticated-read for easy secured downloads.

Includes integration with ActiveAdmin

Rails 3.2.x and Rails4 support

## Getting Started

Add to your Gemfile:

```ruby
gem 'effective_assets'
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

If you want to tweak the table name (to use something other than the default `assets` and `attachments`), manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

If you intend to use the form helper method to display and upload assets, require the javascript in your application.js:

```ruby
//= require effective_assets
```

and the stylesheet in your application.css:

```ruby
*= require effective_assets
```

If you intend to use ActiveAdmin (optional):

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

## Create/Configure an S3 Bucket

You will need an AWS IAM user with sufficient priviledges and a properly configured S3 bucket to use with effective_assets

### Log into AWS Console

- Visit http://aws.amazon.com/console/
- Click My Account from top-right and sign in with your AWS account.

### Create an S3 Bucket

- Click Services -> S3 from the top-left menu
- Click Create Bucket
  - Give the Bucket a name, and select the US Standard region

### Configure CORS Permissions

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

### Create an IAM User and record its AWS Access Keys

- After logging in to your AWS console

- Click Services -> IAM from the top-left

- Select Users from the left-side menu
- Click Create New Users
- Create just one user with any name

- Expand the Show User Security Credentials
- This displays the AWS Access Key and Secret Access Key.
- (important) These are the two values you should copy into the effective_assets.rb initializer file

- Once the user is created, Click on the User Properties area
- Click Attach User Policy
- Scroll down and Select 'Amazon S3 Full Access'

This user is now set up and ready to access the S3 Bucket previously created

### Add S3 Access Keys

Add the name of your S3 Bucket, Access Key and Secret Access Key to the config/initializers/effective_assets.rb file.

```ruby
config.aws_bucket = 'my-bucket'
config.aws_access_key_id = 'ABCDEFGHIJKLMNOP'
config.aws_secret_access_key = 'xmowueroewairo74pacja1/werjow'
```

You should now be able to upload to this bucket.


## Usage

### Model

Use the `acts_as_asset_box` mixin to define a set of 'boxes' all your assets are grouped into.  A box is just a category, which can have any name.

If the box is declared using a singular word, such as `:photo` it will be set up as a `has_one` asset.  When defined as a plural, such as `:photos` it implies a `has_many` assets.

The following will create 4 separate boxes of assets:

```ruby
class User
  acts_as_asset_box :avatar, :photos, :videos, :mp3s
end
```

Calling `user.avatar` will return a single `Effective::Asset`.  Calling `user.photos` will return an array of `Effective::Assets`.

Then to get the URL of an asset:

```ruby
asset = user.avatar
  => an Effective::Asset

asset.url
  => "http://aws_bucket.s3.amazonaws.com/assets/1/my_avatar.png"

asset.url(:thumb)   # See image versions (below)
  => "http://aws_bucket.s3.amazonaws.com/assets/1/thumb_my_avatar.png"

user.photos
  => [Effective::Asset<1>, Effective::Asset<2>] # An array of Effective::Asset objects
```

### Validations

```ruby
class User
  acts_as_asset_box :avatar => true, :photos => false, :videos => 2, :mp3s => 5..10
end
```

true means presence, false means no validations applied.

The user in this example is only valid if exists an avatar, 2 videos, and 5..10 mp3s.

### Form Input

There is a standard rails form input:

```ruby
= form_for @user do |f|
  = f.asset_box_input :pictures
```

A SimpleForm input:

```ruby
= simple_form_for @user do |f|
  = f.input :pictures, :as => :asset_box
```

and a Formtastic input:

```ruby
= semantic_form_for @user do |f|
  = f.input :pictures, :as => :asset_box
```

The `:as => :asset_box` will work interchangeably with SimpleForm or Formtastic, as long as only one of these gems is present in your application.

If you use both SimpleForm and Formtastic, you will need to call asset_box_input differently:

```ruby
= simple_form_for @user do |f|
  = f.input :pictures, :as => :asset_box_simple_form

= semantic_form_for @user do |f|
  = f.input :pictures, :as => :asset_box_formtastic
```


### Uploading & Attaching

Use the custom form input for uploading (direct to S3) and attaching assets to the `pictures` box.

```ruby
= f.input :pictures, :as => :asset_box, :uploader => true

= f.input :pictures, :as => :asset_box, :limit => 2, :file_types => [:jpg, :gif, :png]

= f.input :pictures, :as => :asset_box, :dialog => true, :dialog_url => '/admin/effective_assets' # Use the attach dialog
```

You may also upload secure (AWS: 'authenticated-read') assets with the same uploader

```ruby
= f.input :pictures, :as => :asset_box, :aws_acl => 'authenticated-read'
```

There is also a mechanism for collecting additional information from the upload form which will be set in the `asset.extra` field.

```ruby
= semantic_form_for Product.new do |f|
  = f.input :photos, :as => :asset_box
  = f.semantic_fields_for :photos do |pf|
    = pf.input :field1, :as => :string
    = pf.input :field2, :as => :boolean
```

Here the semantic_fields_for will create some inputs with name

```ruby
product[photos][field1]
product[photos][field2]
```

Any additional field like this will be passed to the Asset and populate the `extra` Hash attribute

Note: Passing :limit => 2 will have no effect on a singular asset_box, which by definition has a limit of 1.

We use the jQuery-File-Upload gem for direct-to-s3 uploading.  The process is as follows:

- User sees the form and clicks Browse.  Selects 1 or more files, then clicks Start Uploading.
- The server makes a post to the S3UploadsController#create action to initialize an asset, and get a unique ID
- The file is uploaded directly to its 'final' resting place on S3 via Javascript uploader at `assets/:id/:filename`
- A PUT is then made back to the S3UploadsController#update which updates the `Effective::Asset` object and sets up a task in `DelayedJob` to process the asset (for image resizing)
- An `Effective::Attachment` is created, which joins the `Effective::Asset` to the parent Object (`User` in our example) in the appropriate position.
- The `DelayedJob` task should be running and will handle any image resizing as defined by the `AssetUploader`.
- The asset will appear in the form, and the user may click&drag the asset around to set the position.


### Strong Parameters

Make your controller aware of the acts_as_asset_box passed parameters:

```ruby
def permitted_params
  params.require(:base_object).permit(EffectiveAssets.permitted_params)
end
```

The permitted parameters are:

```ruby
:attachments_attributes => [:id, :asset_id, :attachable_type, :attachable_id, :position, :box, :_destroy]
```


### Image Processing and Resizing

CarrierWave and DelayedJob are used by this gem to perform image versioning.

This will be moved over to the new ActiveJob API in future versions of this gem, but right now DelayedJob is the only supported background worker.

See the installer created at `app/uploaders/asset_uploader.rb` to configure image versions.

Use the `process :record_info => :thumb` directive to store image version dimensions and file sizes.

When this uploader file is changed, you must reprocess any existing `Effective::Asset` objects to recreate all image versions.

This one-liner downloads the original file from AWS S3, creates the image versions locally using imagemagick, then uploads each version to its final resting place back on AWS S3.

```ruby
Effective::Asset.find(123).reprocess!
=> true
```

This can be done in batch using the built in rake script (see below).

### Helpers

You can always get the URL directly

```ruby
current_user.avatar.url(:thumb)
```

To display the asset as a link with an image (if its an image, or a mime-type appropriate icon if its not an image):

```ruby
# Asset is the @user.fav_icon
# version is anything you set up in your uploaders/asset_uploader.rb as versions.  :thumb
# Options are passed through to a call to rails image_tag helper
effective_asset_image_tag(asset, version = nil, options = {})
```

To display the asset as a link with no image:

```ruby
# Options are passed through to rails link_to helper
effective_asset_link_to(asset, version = nil, options = {})
```

## Authorization

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

### Permissions

To allow user uploads, using Cancan:

```ruby
can [:create, :update, :destroy], Effective::Asset, :user_id => user.id
```


## Rake Tasks

Use the following rake tasks to aid in batch processing a large number of (generally image) files.

### Reprocess

If the `app/uploaders/asset_uploader.rb` file is changed, run the following rake task to reprocess all `Effective::Asset` objects and thereby recreate all image versions

```ruby
rake effective_assets:reprocess           # All assets
rake effective_assets:reprocess[200]      # reprocess #200 and up
rake effective_assets:reprocess[1,200]    # reprocess #1..#200
```

This command enqueues a `.reprocess!` job for each `Effective::Asset` on the `DelayedJob` queue.

If a `DelayedJob` worker process is already running, the reprocessing will begin immediately, otherwise start one with

```ruby
rake jobs:work
```

### Check

Checks every `Effective::Asset` and all its versions for a working URL (200 http status code).

Any non-200 http responses are logged as an error.

This is a sanity-check task, that makes sure every url for every asset and version is going to work.

This is just single-threaded one process.

If you need to check a large number of urls, use multiple rake tasks and pass in ID ranges. Sorry.

```ruby
rake effective_assets:check         # check that every version of every Effective::Asset is a valid http 200 OK url
rake effective_assets:check[200]    # check #200 and up
rake effective_assets:check[1,200]  # check #1..#200
rake effective:assets:check[1,200,:thumb]   # check #1..#200 only :thumb versions
```

### Clear

Deletes all effective_assets related jobs on the DelayedJob queue.

```ruby
rake effective_assets:clear
```

or to clear all jobs, even non-effective_assets related jobs, use DelayedJob's rake task:

```ruby
rake jobs:clear
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

Code and Effect is the product arm of [AgileStyle](http://www.agilestyle.com/), an Edmonton-based shop that specializes in building custom web applications with Ruby on Rails.


## Credits

This gem heavily relies on:

CarrierWave (https://github.com/carrierwaveuploader/carrierwave)

DelayedJob (https://github.com/collectiveidea/delayed_job)

jQuery-File-Upload (https://github.com/blueimp/jQuery-File-Upload)


## Testing

Testing uses the Combustion gem, for easier Rails Engine Testing.

https://github.com/pat/combustion

You will need a valid initializer in spec/internal/config/initializers/effective_assets.rb

Run tests by

```ruby
bundle exec guard
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

