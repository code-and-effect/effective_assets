# Effective Assets

A full solution for managing assets (images, files, videos, etc).

Attach one or more assets to any model with validations.

Includes an upload direct to Amazon S3 implementation based on jQuery-File-Upload and image processing in the background with CarrierWave and DelayedJob

Both Formtastic and SimpleForm inputs for displaying, organizing, and uploading assets direct to s3.

Includes (optional but recommended) integration with ActiveAdmin

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
@import "effective_assets";
```

If ActiveAdmin is installed, there will automatically be an 'Effective Assets' page.

## Usage

### Model

When including the acts_as_asset_box mixin, the idea of 'boxes' is presented.  A box is just a category, which can have any name.

If the box is declared as a singular, 'photo', then it will be a singular asset.  When defined as a plural, 'photos', it will be a set of photos.

The following will create 3 separate sets of assets:

```ruby
class User
  acts_as_asset_box :fav_icon, :pictures, :logos
end
```

Calling @user.fav_icon will return a single Effective::Asset.  Calling @user.pictures will return an array of Effective::Assets

To use with validations:

```ruby
class User
  acts_as_asset_box :fav_icon => true, :pictures => false, :videos => 2, :images => 5..10
end
```

The user in this example is only valid if exists a fav_icon, 2 videos, and 5..10 images.

### Uploading & Attaching

Use the custom Formtastic input for uploading (direct to S3) and attaching assets to the 'pictures' box.

```ruby
= f.input :pictures, :as => :asset_box, :uploader => true
= f.input :videos, :as => :asset_box, :limit => 2, :file_types => [:jpg, :gif, :png], :attachment_style => :table

= f.input :pictures, :as => :asset_box, :dialog => true, :dialog_url => '/admin/effective_assets' # Use the attach dialog

```

Use the custom SimpleForm input for uploading (direct to S3) and attaching assets to the 'pictures' box.

```ruby
= f.input :pictures, :as => :asset_box_simple_form, :uploader => true
= f.input :videos, :as => :asset_box_simple_form, :limit => 2, :file_types => [:jpg, :gif, :png]

= f.input :pictures, :as => :asset_box_simple_form, :dialog => true, :dialog_url => '/admin/effective_assets' # Use the attach dialog
```

Note: Passing :limit => 2 will have no effect on a singular asset_box, which by definition has a limit of 1.

We use the jQuery-File-Upload gem for direct-to-s3 uploading.  The process is as follows:

- User sees the form and clicks Browse.  Selects 1 or more files, then clicks Start Uploading
- The server makes a post to the S3UploadsController#create action to initialize an asset, and get a unique ID
- The file is uploaded directly to its 'final' resting place. "assets/:id/filename"
- A put is then made back to the effective#s3_uploads_controller#update which updates the Asset object and sets up a task in DelayedJob to process the asset (for image resizing)
- An attachment is created, which joins the Asset to the parent Object (User in our example) in the appropriate position.
- The DelayedJob task should be running and will handle any image resizing as defined by the AssetUploader
- The asset will appear in the form, and the user may click&drag the asset around to set the position.

### Authorization

All authorization checks are handled via the config.authorization_method found in the effective_assets.rb initializer.

It is intended for flow through to CanCan, but that is not required.

The authorization method can be defined as:

```ruby
EffectiveAssets.setup do |config|
  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) }
end
```

or as a method:

```ruby
EffectiveAssets.setup do |config|
  config.authorization_method = :authorize_effective_assets
end
```

and then in your application_controller.rb:

```ruby
def authorize_effective_assets(action, resource)
  can?(action, resource)
end
```

The action will be one of :read, :create, :update, :destroy, :manage
The resource will generally be the @asset, but in the case of :manage, it is Effective::Asset class.

If the method or proc returns false (user is not authorized) an ActiveResource::UnauthorizedAccess exception will be raised

You can rescue from this exception by adding the following to your application_controller.rb

```ruby
rescue_from ActiveResource::UnauthorizedAccess do |exception|
  respond_to do |format|
    format.html { render 'static_pages/access_denied', :status => 403 }
    format.any { render :text => 'Access Denied', :status => 403 }
  end
end
```

### Strong Parameters

Make your controller aware of the acts_as_asset_box passed parameters:

```ruby
def permitted_params
  params.require(:base_object).permit(:attachments_attributes => [:id, :asset_id, :attachable_type, :attachable_id, :position, :box, :_destroy])
end
```

### Image Processing and Resizing

CarrierWave is used under the covers to do all the image resizing.
The installer created an uploaders/asset_uploader.rb which you can use to set up versions.

Some additional processing goes on to record final image dimensions and file sizes.


### Helpers

To just get the URL of an asset

```ruby
@asset = @user.fav_icon
@asset.url
  => "http://aws_bucket.s3.amazonaws.com/assets/1/my_favorite_icon.png
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

### Integration

The 'Insert Asset' functionality from this gem is used in effective_mercury and effective_rte


## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect

## Credits

This gem heavily relies on:

CarrierWave (https://github.com/carrierwaveuploader/carrierwave)

DelayedJob (https://github.com/collectiveidea/delayed_job)

jQuery-File-Upload (https://github.com/blueimp/jQuery-File-Upload)


### Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```
