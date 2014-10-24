module Inputs
  module AssetBoxFormInput
    def asset_box_input(method, opts = {})
      AssetBox.new(@object, @object_name, @template, method, opts).to_html
    end
  end
end
