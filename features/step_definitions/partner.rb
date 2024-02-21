# frozen_string_literal: true

Given('there are some partner types') do |table|
  table.hashes.each do |attr|
    PartnerType.create!(**attr)
  end
end

Given('there are some partners') do |table|
  table.hashes.each do |attr|
    attr['type'] = PartnerType.i18n.find_by!(name: attr.delete('type'))
    attr['logo'] = uploaded_thumbnail(attr['logo'])

    Partner.create!(**attr)
  end
end
