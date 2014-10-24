module Inputs
  module AssetBoxFormBuilder
    def asset_box_input(method, opts = {})
      @@uid = (@@uid ||= 0) + 1 # We just need a unique number to pass along, incase we have multiple Uploaders per form
      AssetBox.new(@object, @object_name, @template, @@uid, method, opts).to_html
    end
  end
end
