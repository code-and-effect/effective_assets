# With formtastic, just use
#
# = f.input :pictures, :as => :asset_box
# = f.input :fav_icon, :as => :asset_box, :limit => 4, :file_types => [:jpg, :gif, :png]
# = f.input :logo, :as => :asset_box, :uploader => false, :dialog => true
# = f.input :logo, :as => :asset_box, :uploader => true

if defined?(Formtastic)
  class AssetBoxInput
    include ::Formtastic::Inputs::Base
    include AssetBox
  end
end
