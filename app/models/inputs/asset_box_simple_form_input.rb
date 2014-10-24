if defined?(SimpleForm)
  class AssetBoxSimpleFormInput < SimpleForm::Inputs::FileInput
    def input(wrapper_options = nil)
      Inputs::AssetBox.new(object, object_name, template, attribute_name, options).to_html
    end
  end
end
