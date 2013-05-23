class AssetBoxLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    num_in_box = (record.attachments || []).select { |attachment| attachment.box == attribute.to_s.pluralize }.size

    if options[:with]
      record.errors[attribute] << "requires at least #{options[:with]} #{attribute.to_s.pluralize}" if num_in_box < options[:with]
    elsif options[:in]
      record.errors[attribute] << "requires #{options[:in].min} to #{options[:in].max} #{attribute.to_s.pluralize}" if options[:in].include?(num_in_box) == false
    end
  end
end
