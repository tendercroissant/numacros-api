class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    
    email = ValidEmail2::Address.new(value)
    unless email.valid?
      record.errors.add(attribute, :invalid)
    end
  end
end 