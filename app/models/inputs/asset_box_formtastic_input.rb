if defined?(Formtastic)
  class AssetBoxFormtasticInput < Formtastic::Inputs::FileInput
    def to_html
      input_wrapping do
        label_html << Inputs::AssetBox.new(@object, @object_name, @template, @method, @options).to_html
      end
    end
  end
end
