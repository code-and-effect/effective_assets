class AssetBoxPresenceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    num_in_box = (record.attachments || []).select { |attachment| attachment.box == attribute.to_s.pluralize }.size
    record.errors[attribute] << "can't be blank" if num_in_box == 0
  end
end
