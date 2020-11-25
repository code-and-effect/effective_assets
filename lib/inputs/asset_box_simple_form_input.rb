class AssetBoxSimpleFormInput < defined?(SimpleForm) ? SimpleForm::Inputs::FileInput : Object
  def input(wrapper_options = nil)
    AssetBox.new(object, object_name, template, attribute_name, options).to_html
  end
end
