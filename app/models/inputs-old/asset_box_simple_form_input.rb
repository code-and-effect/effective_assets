# = f.input :pictures, :as => :asset_box_simple_form
# = f.input :fav_icon, :as => :asset_box_simple_form, :limit => 4, :file_types => [:jpg, :gif, :png]
# = f.input :logo, :as => :asset_box_simple_form, :uploader => false, :dialog => true

# = f.input :logo, :as => :asset_box_simple_form, :uploader => true

if defined?(SimpleForm)
  class AssetBoxSimpleFormInput < SimpleForm::Inputs::Base
    include AssetBox

    def input # SimpleForm calls .input
      to_html
    end

    # Redefines some of the Formtastic specific methods so this will work with simple_form with no other changes.
    # def method (*args)
    #   method(attribute_name)
    # end

    #def method(*args) ; attribute_name ; end
    def input_wrapping(&block) ; yield ; end
    def label_html ; '' ; end
  end
end
