class AssetBoxInput < SimpleForm::Inputs::FileInput
  def input(wrapper_options)
    @@uid = (@@uid ||= 0) + 1 # We just need a unique number to pass along, incase we have multiple Uploaders per form

    Inputs::AssetBox.new(object, object_name, template, @@uid, attribute_name, options).to_html
  end

end
