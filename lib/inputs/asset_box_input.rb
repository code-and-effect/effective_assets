# This allows the app to call f.input :something, :as => :asset_box
# in either Formtastic or SimpleForm, but not both at the same time

if defined?(SimpleForm)
  class AssetBoxInput < SimpleForm::Inputs::FileInput
    def input(wrapper_options = nil)
      AssetBox.new(object, object_name, template, attribute_name, options).to_html
    end
  end
elsif defined?(Formtastic)
  class AssetBoxInput < Formtastic::Inputs::FileInput
    def to_html
      input_wrapping do
        label_html << AssetBox.new(@object, @object_name, @template, @method, @options).to_html
      end
    end
  end
else
  class AssetBoxInput < Object
    def to_html
      'expected simpleform or formtastic'
    end
  end
end
