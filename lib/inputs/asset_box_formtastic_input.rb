class AssetBoxFormtasticInput < defined?(Formtastic) ? Formtastic::Inputs::FileInput : Object
  def to_html
    input_wrapping do
      label_html << AssetBox.new(@object, @object_name, @template, @method, @options).to_html
    end
  end
end
